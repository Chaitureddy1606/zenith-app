//
//  TaskManager.swift
//  app-ai
//
//  Created by chaitu on 27/08/25.
//

import Foundation
import UserNotifications
import Combine
import SwiftUI
import UIKit

/// Centralized task management system handling all task operations
@MainActor
class TaskManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// All tasks in the system
    @Published var tasks: [Task] = []
    
    /// Current search query for filtering
    @Published var searchText: String = ""
    
    /// Selected view mode (inbox, history, etc.)
    @Published var viewMode: ViewMode = .inbox
    
    /// Loading state for async operations
    @Published var isLoading: Bool = false
    
    /// Error state for user feedback
    @Published var errorMessage: String?
    
    // MARK: - View Mode
    
    enum ViewMode: String, CaseIterable {
        case inbox = "Inbox"
        case history = "History"
        case search = "Search"
    }
    
    // MARK: - Computed Properties
    
    /// Tasks filtered by current view mode and search
    var filteredTasks: [Task] {
        let baseTasks: [Task]
        
        switch viewMode {
        case .inbox:
            baseTasks = tasks.filter { !$0.isCompleted && $0.status != .archived }
        case .history:
            baseTasks = tasks.filter { $0.isCompleted || $0.status == .archived }
        case .search:
            baseTasks = tasks
        }
        
        // Apply search filter
        if searchText.isEmpty {
            return baseTasks.sorted { task1, task2 in
                // Sort by priority first, then by due date
                if task1.priority.sortOrder != task2.priority.sortOrder {
                    return task1.priority.sortOrder > task2.priority.sortOrder
                }
                
                // Handle due dates
                switch (task1.dueDate, task2.dueDate) {
                case (.some(let date1), .some(let date2)):
                    return date1 < date2
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return task1.createdAt > task2.createdAt
                }
            }
        } else {
            return baseTasks.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.notes.localizedCaseInsensitiveContains(searchText) ||
                task.tags.contains { $0.rawValue.localizedCaseInsensitiveContains(searchText) } ||
                task.location?.address?.localizedCaseInsensitiveContains(searchText) == true ||
                task.location?.name?.localizedCaseInsensitiveContains(searchText) == true
            }.sorted { task1, task2 in
                task1.priority.sortOrder > task2.priority.sortOrder
            }
        }
    }
    
    /// Tasks grouped by completion date for history view
    var groupedHistoryTasks: [(String, [Task])] {
        let historyTasks = tasks.filter { $0.isCompleted || $0.status == .archived }
        let grouped = Dictionary(grouping: historyTasks) { task in
            let date = task.completedAt ?? task.updatedAt
            return DateFormatter.dayGroupFormatter.string(from: date)
        }
        
        return grouped.map { (key, value) in
            (key, value.sorted { $0.completedAt ?? $0.updatedAt > $1.completedAt ?? $1.updatedAt })
        }.sorted { $0.0 > $1.0 }
    }
    
    /// Statistics for dashboard
    var taskStats: TaskStats {
        let pending = tasks.filter { $0.status == .pending }.count
        let inProgress = tasks.filter { $0.status == .inProgress }.count
        let completed = tasks.filter { $0.isCompleted }.count
        let overdue = tasks.filter { $0.isOverdue }.count
        
        return TaskStats(
            pending: pending,
            inProgress: inProgress,
            completed: completed,
            overdue: overdue,
            total: tasks.count
        )
    }
    
    // MARK: - Initialization
    
    init() {
        setupNotifications()
        loadTasks()
    }
    
    // MARK: - Task Operations
    
    /// Add a new task
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
        
        // Schedule notification if reminder is enabled
        if task.reminderEnabled, let reminderDate = task.reminderDate {
            scheduleNotification(for: task, at: reminderDate)
        }
    }
    
    /// Update an existing task
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            task.updateMetadata()
            saveTasks()
            
            // Update notification
            cancelNotification(for: task)
            if task.reminderEnabled, let reminderDate = task.reminderDate {
                scheduleNotification(for: task, at: reminderDate)
            }
        }
    }
    
    /// Delete a task
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        cancelNotification(for: task)
        saveTasks()
    }
    
    /// Toggle task completion with animation
    func toggleTaskCompletion(_ task: Task) {
        SwiftUI.withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            task.toggleCompletion()
            updateTask(task)
        }
        
        // Provide haptic feedback
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(task.isCompleted ? .success : .warning)
    }
    
    /// Reschedule a task to a new date
    func rescheduleTask(_ task: Task, to newDate: Date) {
        task.dueDate = newDate
        if task.reminderEnabled {
            task.reminderDate = newDate
        }
        updateTask(task)
    }
    
    /// Archive a task
    func archiveTask(_ task: Task) {
        task.status = .archived
        updateTask(task)
    }
    
    // MARK: - Search and Filtering
    
    /// Clear search and reset to inbox view
    func clearSearch() {
        searchText = ""
        viewMode = .inbox
    }
    
    /// Set search mode and query
    func searchTasks(with query: String) {
        searchText = query
        viewMode = .search
    }
    
    // MARK: - Data Persistence
    
    private var tasksFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("tasks.json")
    }
    
    /// Save tasks to persistent storage
    private func saveTasks() {
        do {
            let data = try JSONEncoder().encode(tasks)
            try data.write(to: tasksFileURL)
        } catch {
            print("Failed to save tasks: \(error)")
            errorMessage = "Failed to save tasks"
        }
    }
    
    /// Load tasks from persistent storage
    private func loadTasks() {
        do {
            let data = try Data(contentsOf: tasksFileURL)
            tasks = try JSONDecoder().decode([Task].self, from: data)
        } catch {
            print("Failed to load tasks: \(error)")
            // Load sample data if no saved tasks exist
            tasks = Task.sampleTasks
            saveTasks()
        }
    }
    
    // MARK: - Notifications
    
    /// Setup notification permissions
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    /// Schedule a notification for a task
    private func scheduleNotification(for task: Task, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default
        content.badge = 1
        
        // Add action buttons
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Mark Complete",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 15min",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "TASK_REMINDER"
        
        // Create trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "task_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    /// Cancel notification for a task
    private func cancelNotification(for task: Task) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["task_\(task.id.uuidString)"]
        )
    }
    
    /// Handle notification actions
    func handleNotificationAction(_ action: String, for taskId: String) {
        guard let task = tasks.first(where: { $0.id.uuidString == taskId }) else { return }
        
        switch action {
        case "COMPLETE_ACTION":
            toggleTaskCompletion(task)
        case "SNOOZE_ACTION":
            let snoozeDate = Date().addingTimeInterval(15 * 60) // 15 minutes
            rescheduleTask(task, to: snoozeDate)
        default:
            break
        }
    }
}

// MARK: - Task Statistics

/// Task statistics for dashboard and analytics
struct TaskStats {
    let pending: Int
    let inProgress: Int
    let completed: Int
    let overdue: Int
    let total: Int
    
    var completionRate: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
    
    var overdueRate: Double {
        guard total > 0 else { return 0 }
        return Double(overdue) / Double(total)
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let dayGroupFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
} 