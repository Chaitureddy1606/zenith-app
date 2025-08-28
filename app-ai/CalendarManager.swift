import Foundation
import SwiftUI
import UserNotifications
import Combine
import EventKit
@preconcurrency import CoreLocation

// MARK: - Calendar Manager

/// Main calendar management class handling events, search, AI features, and notifications
@MainActor
class CalendarManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var events: [CalendarEvent] = []
    @Published var currentDate = Date()
    @Published var selectedDate = Date()
    @Published var viewMode: CalendarViewMode = .month
    @Published var searchText = ""
    @Published var searchScope: EventSearchScope = .all
    @Published var eventFilter = EventFilter()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingJumpToDate = false
    @Published var showingSearch = false
    @Published var showingEventDetail: CalendarEvent?
    @Published var showingAddEvent = false
    @Published var selectedTimeSlot: Date?
    @Published var conflictingEvents: [CalendarEvent] = []
    @Published var aiSuggestions: [AISuggestion] = []
    @Published var notificationBadgeCount = 0
    @Published var isLocationAuthorized = false
    
    // MARK: - Private Properties
    
    private let calendar = Calendar.current
    private let notificationCenter = UNUserNotificationCenter.current()
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Events filtered by current search and filter criteria
    var filteredEvents: [CalendarEvent] {
        events.filter { event in
            eventFilter.matches(event, searchText: searchText)
        }
    }
    
    /// Events for today
    var todaysEvents: [CalendarEvent] {
        events(for: Date())
    }
    
    /// Upcoming events (next 7 days)
    var upcomingEvents: [CalendarEvent] {
        let endDate = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return events.filter { event in
            event.startDate >= Date() && event.startDate <= endDate
        }.sorted { $0.startDate < $1.startDate }
    }
    
    /// Events currently happening
    var currentEvents: [CalendarEvent] {
        let now = Date()
        return events.filter { event in
            event.startDate <= now && event.endDate >= now
        }
    }
    
    /// Next upcoming event
    var nextEvent: CalendarEvent? {
        upcomingEvents.first
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupNotifications()
        setupLocationServices()
        loadSampleData()
        detectConflicts()
        generateAISuggestions()
        updateBadgeCount()
    }
    
    // MARK: - Event Management
    
    /// Add a new event
    func addEvent(_ event: CalendarEvent) {
        withAnimation(.spring()) {
            events.append(event)
            event.modifiedDate = Date()
        }
        detectConflicts()
        scheduleNotifications(for: event)
        updateBadgeCount()
        generateAISuggestions()
    }
    
    /// Update an existing event
    func updateEvent(_ event: CalendarEvent) {
        withAnimation(.spring()) {
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                events[index] = event
                event.modifiedDate = Date()
            }
        }
        detectConflicts()
        scheduleNotifications(for: event)
        updateBadgeCount()
        generateAISuggestions()
    }
    
    /// Delete an event
    func deleteEvent(_ event: CalendarEvent) {
        withAnimation(.spring()) {
            events.removeAll { $0.id == event.id }
        }
        cancelNotifications(for: event)
        detectConflicts()
        updateBadgeCount()
        generateAISuggestions()
    }
    
    /// Get events for a specific date
    func events(for date: Date) -> [CalendarEvent] {
        events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date) ||
            (event.isAllDay && calendar.isDate(event.startDate, inSameDayAs: date))
        }.sorted { $0.startDate < $1.startDate }
    }
    
    /// Get events for a specific hour on a date
    func events(for date: Date, hour: Int) -> [CalendarEvent] {
        let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
        let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart) ?? hourStart
        
        return events.filter { event in
            !event.isAllDay &&
            event.startDate < hourEnd &&
            event.endDate > hourStart
        }
    }
    
    /// Create event from task
    func createEventFromTask(_ task: Task, at date: Date) {
        let event = CalendarEvent(
            title: task.title,
            startDate: date,
            endDate: calendar.date(byAdding: .hour, value: 1, to: date) ?? date
        )
        
        event.notes = task.notes
        event.priority = mapTaskPriorityToEvent(task.priority)
        event.location = task.location.map { taskLocation in
            EventLocation(
                name: taskLocation.name ?? "Unknown Location",
                address: taskLocation.address,
                latitude: taskLocation.latitude,
                longitude: taskLocation.longitude
            )
        }
        
        addEvent(event)
    }
    
    // MARK: - Date Navigation
    
    /// Navigate to today
    func goToToday() {
        withAnimation(.spring()) {
            selectedDate = Date()
            currentDate = Date()
        }
    }
    
    /// Navigate to specific date
    func jumpToDate(_ date: Date) {
        withAnimation(.spring()) {
            selectedDate = date
            currentDate = date
            showingJumpToDate = false
        }
    }
    
    /// Navigate to previous period based on current view mode
    func goToPrevious() {
        withAnimation(.spring()) {
            switch viewMode {
            case .day:
                selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            case .week:
                selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
            case .month:
                selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
            case .year:
                selectedDate = calendar.date(byAdding: .year, value: -1, to: selectedDate) ?? selectedDate
            }
            currentDate = selectedDate
        }
    }
    
    /// Navigate to next period based on current view mode
    func goToNext() {
        withAnimation(.spring()) {
            switch viewMode {
            case .day:
                selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            case .week:
                selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
            case .month:
                selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
            case .year:
                selectedDate = calendar.date(byAdding: .year, value: 1, to: selectedDate) ?? selectedDate
            }
            currentDate = selectedDate
        }
    }
    
    // MARK: - Search and Filtering
    
    /// Clear search
    func clearSearch() {
        searchText = ""
        showingSearch = false
    }
    
    /// Apply filter
    func applyFilter(_ filter: EventFilter) {
        withAnimation(.spring()) {
            eventFilter = filter
        }
    }
    
    /// Reset filter to defaults
    func resetFilter() {
        withAnimation(.spring()) {
            eventFilter = EventFilter()
        }
    }
    
    // MARK: - Conflict Detection
    
    /// Detect conflicts between events
    private func detectConflicts() {
        var conflicted: [CalendarEvent] = []
        
        for i in 0..<events.count {
            for j in (i+1)..<events.count {
                if events[i].conflictsWith(events[j]) {
                    conflicted.append(events[i])
                    conflicted.append(events[j])
                }
            }
        }
        
        // Update conflict status
        for event in events {
            event.isConflicted = conflicted.contains { $0.id == event.id }
        }
        
        conflictingEvents = Array(Set(conflicted))
    }
    
    // MARK: - Notifications
    
    /// Setup notification permissions
    private func setupNotifications() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
        
        // Register notification actions
        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze.rawValue,
            title: NotificationAction.snooze.title,
            options: []
        )
        
        let viewAction = UNNotificationAction(
            identifier: NotificationAction.view.rawValue,
            title: NotificationAction.view.title,
            options: [.foreground]
        )
        
        let attendingAction = UNNotificationAction(
            identifier: NotificationAction.markAttending.rawValue,
            title: NotificationAction.markAttending.title,
            options: []
        )
        
        let notAttendingAction = UNNotificationAction(
            identifier: NotificationAction.markNotAttending.rawValue,
            title: NotificationAction.markNotAttending.title,
            options: []
        )
        
        let eventCategory = UNNotificationCategory(
            identifier: "EVENT_REMINDER",
            actions: [snoozeAction, viewAction, attendingAction, notAttendingAction],
            intentIdentifiers: []
        )
        
        notificationCenter.setNotificationCategories([eventCategory])
    }
    
    /// Schedule notifications for an event
    private func scheduleNotifications(for event: CalendarEvent) {
        // Cancel existing notifications
        cancelNotifications(for: event)
        
        // Schedule new notifications for each alert
        for alert in event.alerts {
            let notificationDate = event.startDate.addingTimeInterval(alert.timeInterval)
            
            guard notificationDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = event.title
            content.body = event.timeRangeText
            content.sound = .default
            content.categoryIdentifier = "EVENT_REMINDER"
            content.userInfo = [
                "eventId": event.id.uuidString,
                "alertId": alert.id.uuidString
            ]
            
            if let location = event.location {
                content.subtitle = location.displayText
            }
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate),
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "\(event.id.uuidString)-\(alert.id.uuidString)",
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error)")
                }
            }
        }
    }
    
    /// Cancel notifications for an event
    private func cancelNotifications(for event: CalendarEvent) {
        let identifiers = event.alerts.map { "\(event.id.uuidString)-\($0.id.uuidString)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    /// Update app badge count
    private func updateBadgeCount() {
        let count = todaysEvents.filter { $0.isUpcoming }.count
        notificationBadgeCount = count
        
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().setBadgeCount(count) { error in
                if let error = error {
                    print("Failed to set badge count: \(error)")
                }
            }
        }
    }
    
    // MARK: - Location Services
    
    /// Setup location services
    private func setupLocationServices() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationAuthorized = true
        case .denied, .restricted:
            isLocationAuthorized = false
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            isLocationAuthorized = false
        }
    }
    
    /// Get current location
    func getCurrentLocation() -> CLLocation? {
        guard isLocationAuthorized else { return nil }
        return locationManager.location
    }
    
    // MARK: - AI Suggestions
    
    /// Generate AI-powered suggestions
    private func generateAISuggestions() {
        var suggestions: [AISuggestion] = []
        
        // Find time suggestions
        if let timeSlot = findOptimalTimeSlot() {
            suggestions.append(AISuggestion(
                type: .findTime,
                title: "Free Time Available",
                description: "Found a 2-hour free slot at \(DateFormatter.shortTime.string(from: timeSlot.startDate))",
                confidence: timeSlot.confidence,
                actionData: [
                    "startDate": timeSlot.startDate,
                    "endDate": timeSlot.endDate
                ],
                relatedEvents: timeSlot.conflictingEvents
            ))
        }
        
        // Conflict resolution suggestions
        if !conflictingEvents.isEmpty {
            suggestions.append(AISuggestion(
                type: .conflictResolution,
                title: "Schedule Conflicts Detected",
                description: "Found \(conflictingEvents.count) conflicting events that need attention",
                confidence: 0.9,
                actionData: [:],
                relatedEvents: conflictingEvents
            ))
        }
        
        // Smart schedule suggestions
        if let smartSuggestion = generateSmartScheduleSuggestion() {
            suggestions.append(smartSuggestion)
        }
        
        withAnimation(.spring()) {
            aiSuggestions = suggestions
        }
    }
    
    /// Find optimal time slot for scheduling
    private func findOptimalTimeSlot(duration: TimeInterval = 7200) -> TimeSlotRecommendation? {
        let startOfDay = calendar.startOfDay(for: Date())
        let _ = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        let workStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: startOfDay) ?? startOfDay
        let workEnd = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: startOfDay) ?? startOfDay
        
        var currentTime = workStart
        
        while currentTime.addingTimeInterval(duration) <= workEnd {
            let slotEnd = currentTime.addingTimeInterval(duration)
            let conflictingEvents = events.filter { event in
                !event.isAllDay &&
                event.startDate < slotEnd &&
                event.endDate > currentTime
            }
            
            if conflictingEvents.isEmpty {
                return TimeSlotRecommendation(
                    startDate: currentTime,
                    endDate: slotEnd,
                    confidence: 0.9,
                    reason: "No conflicts during business hours",
                    conflictingEvents: []
                )
            }
            
            currentTime = currentTime.addingTimeInterval(1800) // 30-minute increments
        }
        
        return nil
    }
    
    /// Generate smart schedule suggestion
    private func generateSmartScheduleSuggestion() -> AISuggestion? {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowEvents = events(for: tomorrow)
        
        if tomorrowEvents.count < 3 {
            return AISuggestion(
                type: .smartSchedule,
                title: "Light Schedule Tomorrow",
                description: "Tomorrow looks like a good day for important tasks",
                confidence: 0.8,
                actionData: ["suggestedDate": tomorrow],
                relatedEvents: tomorrowEvents
            )
        }
        
        return nil
    }
    
    // MARK: - Utility Methods
    
    /// Map task priority to event priority
    private func mapTaskPriorityToEvent(_ taskPriority: TaskPriority) -> EventPriority {
        switch taskPriority {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        }
    }
    
    /// Load sample data for testing
    private func loadSampleData() {
        let sampleEvents = [
            CalendarEvent(
                title: "Team Meeting",
                startDate: calendar.date(byAdding: .hour, value: 2, to: Date()) ?? Date(),
                endDate: calendar.date(byAdding: .hour, value: 3, to: Date()) ?? Date()
            ),
            CalendarEvent(
                title: "Lunch with Client",
                startDate: calendar.date(byAdding: .day, value: 1, to: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()) ?? Date(),
                endDate: calendar.date(byAdding: .day, value: 1, to: calendar.date(bySettingHour: 13, minute: 30, second: 0, of: Date()) ?? Date()) ?? Date()
            ),
            CalendarEvent(
                title: "Project Review",
                startDate: calendar.date(byAdding: .day, value: 2, to: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()) ?? Date(),
                endDate: calendar.date(byAdding: .day, value: 2, to: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()) ?? Date()
            ),
            CalendarEvent(
                title: "All-Day Conference",
                startDate: calendar.date(byAdding: .day, value: 3, to: calendar.startOfDay(for: Date())) ?? Date(),
                isAllDay: true
            )
        ]
        
        for event in sampleEvents {
            event.calendarColor = [.blue, .green, .orange, .purple].randomElement() ?? .blue
            event.alerts = [EventAlert(timing: .fifteenMin)]
            events.append(event)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension CalendarManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isLocationAuthorized = true
            case .denied, .restricted:
                self.isLocationAuthorized = false
            case .notDetermined:
                break
            @unknown default:
                self.isLocationAuthorized = false
            }
        }
    }
}

// MARK: - Date Formatters

extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Array Extension

extension Array where Element: Identifiable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element.ID>()
        return filter { seen.insert($0.id).inserted }
    }
} 