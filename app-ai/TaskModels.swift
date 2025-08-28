//
//  TaskModels.swift
//  app-ai
//
//  Created by chaitu on 27/08/25.
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Task Priority

/// Task priority levels with associated colors and display properties
enum TaskPriority: String, CaseIterable, Identifiable, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var id: String { rawValue }
    
    /// Color representation for priority indicators
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
    
    /// Sort order for priority-based filtering
    var sortOrder: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

// MARK: - Task Tag

/// Built-in task tags for categorization
enum TaskTag: String, CaseIterable, Identifiable, Codable, Hashable {
    case work = "Work"
    case personal = "Personal"
    case health = "Health"
    case shopping = "Shopping"
    case travel = "Travel"
    case finance = "Finance"
    case learning = "Learning"
    case social = "Social"
    
    var id: String { rawValue }
    
    /// Color for tag display
    var color: Color {
        switch self {
        case .work: return .blue
        case .personal: return .purple
        case .health: return .green
        case .shopping: return .orange
        case .travel: return .cyan
        case .finance: return .mint
        case .learning: return .indigo
        case .social: return .pink
        }
    }
}

// MARK: - Task Status

/// Task completion and workflow status
enum TaskStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
    case archived = "Archived"
}

// MARK: - Sub Task

/// Sub-task model for task breakdown
struct SubTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
    }
}

// MARK: - Task Location

/// Location data for tasks with coordinates and address
struct TaskLocation: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let name: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(coordinate: CLLocationCoordinate2D, address: String? = nil, name: String? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.address = address
        self.name = name
    }
}

// MARK: - Task Attachment

/// File attachments for tasks
struct TaskAttachment: Identifiable, Codable {
    let id: UUID
    let fileName: String
    let fileType: String
    let filePath: String
    let createdAt: Date
    
    init(fileName: String, fileType: String, filePath: String) {
        self.id = UUID()
        self.fileName = fileName
        self.fileType = fileType
        self.filePath = filePath
        self.createdAt = Date()
    }
    
    /// Check if attachment is an image
    var isImage: Bool {
        ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(fileType.lowercased())
    }
    
    /// Check if attachment is audio
    var isAudio: Bool {
        ["mp3", "wav", "m4a", "aac"].contains(fileType.lowercased())
    }
}

// MARK: - Main Task Model

/// Comprehensive task model with all features
class Task: ObservableObject, Identifiable, Codable {
    var id = UUID()
    @Published var title: String
    @Published var notes: String
    @Published var priority: TaskPriority
    @Published var tags: Set<TaskTag>
    @Published var status: TaskStatus
    @Published var dueDate: Date?
    @Published var reminderEnabled: Bool
    @Published var reminderDate: Date?
    @Published var location: TaskLocation?
    @Published var subTasks: [SubTask]
    @Published var attachments: [TaskAttachment]
    @Published var voiceNoteURL: String?
    
    // Metadata
    let createdAt: Date
    @Published var updatedAt: Date
    @Published var completedAt: Date?
    
    // Computed properties
    var isCompleted: Bool {
        status == .completed
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return Date() > dueDate
    }
    
    var completedSubTasksCount: Int {
        subTasks.filter { $0.isCompleted }.count
    }
    
    var subTasksProgress: Double {
        guard !subTasks.isEmpty else { return 0 }
        return Double(completedSubTasksCount) / Double(subTasks.count)
    }
    
    var hasLocation: Bool {
        location != nil
    }
    
    var hasAttachments: Bool {
        !attachments.isEmpty || voiceNoteURL != nil
    }
    
    // MARK: - Initialization
    
    init(title: String, 
         priority: TaskPriority = .medium,
         tags: Set<TaskTag> = [],
         dueDate: Date? = nil,
         notes: String = "") {
        self.title = title
        self.notes = notes
        self.priority = priority
        self.tags = tags
        self.status = .pending
        self.dueDate = dueDate
        self.reminderEnabled = false
        self.reminderDate = nil
        self.location = nil
        self.subTasks = []
        self.attachments = []
        self.voiceNoteURL = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.completedAt = nil
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, title, notes, priority, tags, status
        case dueDate, reminderEnabled, reminderDate, location
        case subTasks, attachments, voiceNoteURL
        case createdAt, updatedAt, completedAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try container.decode(String.self, forKey: .title)
        notes = try container.decode(String.self, forKey: .notes)
        priority = try container.decode(TaskPriority.self, forKey: .priority)
        tags = try container.decode(Set<TaskTag>.self, forKey: .tags)
        status = try container.decode(TaskStatus.self, forKey: .status)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        reminderEnabled = try container.decode(Bool.self, forKey: .reminderEnabled)
        reminderDate = try container.decodeIfPresent(Date.self, forKey: .reminderDate)
        location = try container.decodeIfPresent(TaskLocation.self, forKey: .location)
        subTasks = try container.decode([SubTask].self, forKey: .subTasks)
        attachments = try container.decode([TaskAttachment].self, forKey: .attachments)
        voiceNoteURL = try container.decodeIfPresent(String.self, forKey: .voiceNoteURL)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(title, forKey: .title)
        try container.encode(notes, forKey: .notes)
        try container.encode(priority, forKey: .priority)
        try container.encode(tags, forKey: .tags)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encode(reminderEnabled, forKey: .reminderEnabled)
        try container.encodeIfPresent(reminderDate, forKey: .reminderDate)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encode(subTasks, forKey: .subTasks)
        try container.encode(attachments, forKey: .attachments)
        try container.encodeIfPresent(voiceNoteURL, forKey: .voiceNoteURL)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
    }
    
    // MARK: - Task Actions
    
    /// Mark task as completed
    func markAsCompleted() {
        status = .completed
        completedAt = Date()
        updatedAt = Date()
    }
    
    /// Mark task as pending
    func markAsPending() {
        status = .pending
        completedAt = nil
        updatedAt = Date()
    }
    
    /// Toggle completion status
    func toggleCompletion() {
        if isCompleted {
            markAsPending()
        } else {
            markAsCompleted()
        }
    }
    
    /// Add a new sub-task
    func addSubTask(_ title: String) {
        subTasks.append(SubTask(title: title))
        updatedAt = Date()
    }
    
    /// Remove a sub-task
    func removeSubTask(at index: Int) {
        guard index < subTasks.count else { return }
        subTasks.remove(at: index)
        updatedAt = Date()
    }
    
    /// Update task metadata
    func updateMetadata() {
        updatedAt = Date()
    }
}

// MARK: - Sample Data

extension Task {
    /// Generate sample tasks for development and testing
    static var sampleTasks: [Task] {
        [
            Task(title: "Complete project proposal", 
                 priority: .high, 
                 tags: [.work], 
                 dueDate: Date().addingTimeInterval(86400),
                 notes: "Include budget analysis and timeline"),
            
            Task(title: "Buy groceries", 
                 priority: .medium, 
                 tags: [.personal, .shopping], 
                 dueDate: Date().addingTimeInterval(3600),
                 notes: "Milk, bread, eggs"),
            
            Task(title: "Schedule dentist appointment", 
                 priority: .low, 
                 tags: [.health], 
                 dueDate: Date().addingTimeInterval(604800),
                 notes: "6-month checkup"),
            
            Task(title: "Plan weekend trip", 
                 priority: .medium, 
                 tags: [.travel, .personal], 
                 dueDate: Date().addingTimeInterval(172800),
                 notes: "Research hotels and activities"),
            
            Task(title: "Review investment portfolio", 
                 priority: .high, 
                 tags: [.finance], 
                 dueDate: Date().addingTimeInterval(259200),
                 notes: "Q4 rebalancing")
        ]
    }
} 