import Foundation
import SwiftUI
import CoreLocation
import Contacts
import UserNotifications
import EventKit

// MARK: - Calendar View Modes

/// Calendar display modes with Apple-style segmented control support
enum CalendarViewMode: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week" 
    case month = "Month"
    case year = "Year"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .day: return "calendar.day.timeline.left"
        case .week: return "calendar"
        case .month: return "calendar.badge.plus"
        case .year: return "calendar.badge.exclamationmark"
        }
    }
}

// MARK: - Event Models

/// Event priority levels with visual indicators
enum EventPriority: String, CaseIterable, Codable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    var systemImage: String {
        switch self {
        case .low: return "circle.fill"
        case .medium: return "circle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
}

/// Recurrence patterns for repeating events
enum RecurrenceRule: String, CaseIterable, Codable, Identifiable {
    case never = "Never"
    case daily = "Every Day"
    case weekdays = "Every Weekday"
    case weekly = "Every Week"
    case biweekly = "Every 2 Weeks"
    case monthly = "Every Month"
    case yearly = "Every Year"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var frequency: EKRecurrenceFrequency? {
        switch self {
        case .never: return nil
        case .daily: return .daily
        case .weekdays: return .daily
        case .weekly: return .weekly
        case .biweekly: return .weekly
        case .monthly: return .monthly
        case .yearly: return .yearly
        case .custom: return nil
        }
    }
}

/// Alert timing options
enum AlertTiming: String, CaseIterable, Codable, Identifiable {
    case atTime = "At time of event"
    case fiveMin = "5 minutes before"
    case fifteenMin = "15 minutes before"
    case thirtyMin = "30 minutes before"
    case oneHour = "1 hour before"
    case twoHours = "2 hours before"
    case oneDay = "1 day before"
    case twoDays = "2 days before"
    case oneWeek = "1 week before"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var timeInterval: TimeInterval {
        switch self {
        case .atTime: return 0
        case .fiveMin: return -300
        case .fifteenMin: return -900
        case .thirtyMin: return -1800
        case .oneHour: return -3600
        case .twoHours: return -7200
        case .oneDay: return -86400
        case .twoDays: return -172800
        case .oneWeek: return -604800
        case .custom: return 0
        }
    }
}

/// Attendee response status
enum AttendeeResponse: String, CaseIterable, Codable {
    case pending = "Pending"
    case accepted = "Accepted"
    case declined = "Declined"
    case tentative = "Tentative"
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .accepted: return .green
        case .declined: return .red
        case .tentative: return .yellow
        }
    }
    
    var systemImage: String {
        switch self {
        case .pending: return "clock"
        case .accepted: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        case .tentative: return "questionmark.circle.fill"
        }
    }
}

/// Time zone model for multi-timezone support
struct EventTimeZone: Codable, Identifiable, Equatable {
    var id = UUID()
    let identifier: String
    let displayName: String
    let abbreviation: String
    
    static let current = EventTimeZone(
        identifier: TimeZone.current.identifier,
        displayName: TimeZone.current.localizedName(for: .standard, locale: .current) ?? "Local",
        abbreviation: TimeZone.current.abbreviation() ?? "GMT"
    )
    
    static let utc = EventTimeZone(
        identifier: "UTC",
        displayName: "Coordinated Universal Time",
        abbreviation: "UTC"
    )
    
    var timeZone: TimeZone {
        TimeZone(identifier: identifier) ?? .current
    }
}

/// Event location with MapKit integration
struct EventLocation: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var isCurrentLocation: Bool = false
    
    init(name: String, address: String? = nil, latitude: Double? = nil, longitude: Double? = nil, isCurrentLocation: Bool = false) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.isCurrentLocation = isCurrentLocation
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude = latitude, let longitude = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var displayText: String {
        if isCurrentLocation {
            return "Current Location"
        }
        return address?.isEmpty == false ? "\(name), \(address!)" : name
    }
}

/// Event attendee with contact integration
struct EventAttendee: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var email: String?
    var phoneNumber: String?
    var response: AttendeeResponse = .pending
    var isOrganizer: Bool = false
    
    init(name: String, email: String? = nil, phoneNumber: String? = nil, response: AttendeeResponse = .pending, isOrganizer: Bool = false) {
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.response = response
        self.isOrganizer = isOrganizer
    }
    
    var displayName: String {
        if isOrganizer {
            return "\(name) (Organizer)"
        }
        return name
    }
}

/// Custom recurrence rule for complex patterns
struct CustomRecurrenceRule: Identifiable, Codable {
    var id = UUID()
    var frequency: EKRecurrenceFrequency = .weekly
    var interval: Int = 1
    var daysOfWeek: [EKRecurrenceDayOfWeek] = []
    var daysOfMonth: [NSNumber] = []
    var monthsOfYear: [NSNumber] = []
    var weeksOfYear: [NSNumber] = []
    var daysOfYear: [NSNumber] = []
    var setPositions: [NSNumber] = []
    var endDate: Date?
    var occurrenceCount: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id, frequency, interval, daysOfMonth, monthsOfYear, weeksOfYear, daysOfYear, setPositions, endDate, occurrenceCount
    }
    
    init() {
        // All properties have default values, so this is all that's needed
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let frequencyRawValue = try container.decode(Int.self, forKey: .frequency)
        frequency = EKRecurrenceFrequency(rawValue: frequencyRawValue) ?? .weekly
        interval = try container.decode(Int.self, forKey: .interval)
        // Convert Int arrays to NSNumber arrays
        let daysOfMonthInts = try container.decode([Int].self, forKey: .daysOfMonth)
        daysOfMonth = daysOfMonthInts.map { NSNumber(value: $0) }
        
        let monthsOfYearInts = try container.decode([Int].self, forKey: .monthsOfYear)
        monthsOfYear = monthsOfYearInts.map { NSNumber(value: $0) }
        
        let weeksOfYearInts = try container.decode([Int].self, forKey: .weeksOfYear)
        weeksOfYear = weeksOfYearInts.map { NSNumber(value: $0) }
        
        let daysOfYearInts = try container.decode([Int].self, forKey: .daysOfYear)
        daysOfYear = daysOfYearInts.map { NSNumber(value: $0) }
        
        let setPositionsInts = try container.decode([Int].self, forKey: .setPositions)
        setPositions = setPositionsInts.map { NSNumber(value: $0) }
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        occurrenceCount = try container.decodeIfPresent(Int.self, forKey: .occurrenceCount)
        // Initialize daysOfWeek as empty array since EKRecurrenceDayOfWeek doesn't conform to Codable
        daysOfWeek = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(frequency.rawValue, forKey: .frequency)
        try container.encode(interval, forKey: .interval)
        // Convert NSNumber arrays to Int arrays
        let daysOfMonthInts = daysOfMonth.map { $0.intValue }
        try container.encode(daysOfMonthInts, forKey: .daysOfMonth)
        
        let monthsOfYearInts = monthsOfYear.map { $0.intValue }
        try container.encode(monthsOfYearInts, forKey: .monthsOfYear)
        
        let weeksOfYearInts = weeksOfYear.map { $0.intValue }
        try container.encode(weeksOfYearInts, forKey: .weeksOfYear)
        
        let daysOfYearInts = daysOfYear.map { $0.intValue }
        try container.encode(daysOfYearInts, forKey: .daysOfYear)
        
        let setPositionsInts = setPositions.map { $0.intValue }
        try container.encode(setPositionsInts, forKey: .setPositions)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encodeIfPresent(occurrenceCount, forKey: .occurrenceCount)
        // Note: daysOfWeek is not encoded as EKRecurrenceDayOfWeek doesn't conform to Codable
    }
    
    var description: String {
        let frequencyText = frequency == .daily ? "day" : frequency == .weekly ? "week" : frequency == .monthly ? "month" : "year"
        let intervalText = interval == 1 ? "" : "Every \(interval) "
        return "\(intervalText)\(frequencyText)"
    }
}

/// Event alert configuration
struct EventAlert: Codable, Identifiable {
    var id = UUID()
    var timing: AlertTiming
    var customInterval: TimeInterval?
    var message: String?
    
    init(timing: AlertTiming, customInterval: TimeInterval? = nil, message: String? = nil) {
        self.timing = timing
        self.customInterval = customInterval
        self.message = message
    }
    
    var timeInterval: TimeInterval {
        return customInterval ?? timing.timeInterval
    }
    
    var displayText: String {
        if let customInterval = customInterval {
            let minutes = abs(customInterval) / 60
            let hours = minutes / 60
            let days = hours / 24
            
            if days >= 1 {
                return "\(Int(days)) day\(days == 1 ? "" : "s") before"
            } else if hours >= 1 {
                return "\(Int(hours)) hour\(hours == 1 ? "" : "s") before"
            } else {
                return "\(Int(minutes)) minute\(minutes == 1 ? "" : "s") before"
            }
        }
        return timing.rawValue
    }
}

/// Calendar color scheme
enum CalendarColor: String, CaseIterable, Codable, Identifiable {
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case blue = "Blue"
    case purple = "Purple"
    case pink = "Pink"
    case brown = "Brown"
    case gray = "Gray"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .brown: return .brown
        case .gray: return .gray
        }
    }
}

/// Main calendar event model
class CalendarEvent: ObservableObject, Identifiable, Codable, Hashable {
    var id = UUID()
    @Published var title: String
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var isAllDay: Bool
    @Published var location: EventLocation?
    @Published var notes: String
    @Published var url: String?
    @Published var priority: EventPriority
    @Published var recurrenceRule: RecurrenceRule
    @Published var customRecurrence: CustomRecurrenceRule?
    @Published var attendees: [EventAttendee]
    @Published var alerts: [EventAlert]
    @Published var calendarColor: CalendarColor
    @Published var timeZone: EventTimeZone
    @Published var createdDate: Date
    @Published var modifiedDate: Date
    @Published var isConflicted: Bool = false
    @Published var travelTime: TimeInterval?
    
    enum CodingKeys: CodingKey {
        case id, title, startDate, endDate, isAllDay, location, notes, url, priority, recurrenceRule, customRecurrence, attendees, alerts, calendarColor, timeZone, createdDate, modifiedDate, isConflicted, travelTime
    }
    
    init(title: String, startDate: Date, endDate: Date? = nil, isAllDay: Bool = false) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate ?? startDate.addingTimeInterval(3600)
        self.isAllDay = isAllDay
        self.location = nil
        self.notes = ""
        self.url = nil
        self.priority = .medium
        self.recurrenceRule = .never
        self.customRecurrence = nil
        self.attendees = []
        self.alerts = []
        self.calendarColor = .blue
        self.timeZone = .current
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.travelTime = nil
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        isAllDay = try container.decode(Bool.self, forKey: .isAllDay)
        location = try container.decodeIfPresent(EventLocation.self, forKey: .location)
        notes = try container.decode(String.self, forKey: .notes)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        priority = try container.decode(EventPriority.self, forKey: .priority)
        recurrenceRule = try container.decode(RecurrenceRule.self, forKey: .recurrenceRule)
        customRecurrence = try container.decodeIfPresent(CustomRecurrenceRule.self, forKey: .customRecurrence)
        attendees = try container.decode([EventAttendee].self, forKey: .attendees)
        alerts = try container.decode([EventAlert].self, forKey: .alerts)
        calendarColor = try container.decode(CalendarColor.self, forKey: .calendarColor)
        timeZone = try container.decode(EventTimeZone.self, forKey: .timeZone)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        modifiedDate = try container.decode(Date.self, forKey: .modifiedDate)
        isConflicted = try container.decodeIfPresent(Bool.self, forKey: .isConflicted) ?? false
        travelTime = try container.decodeIfPresent(TimeInterval.self, forKey: .travelTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(isAllDay, forKey: .isAllDay)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encode(notes, forKey: .notes)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encode(priority, forKey: .priority)
        try container.encode(recurrenceRule, forKey: .recurrenceRule)
        try container.encodeIfPresent(customRecurrence, forKey: .customRecurrence)
        try container.encode(attendees, forKey: .attendees)
        try container.encode(alerts, forKey: .alerts)
        try container.encode(calendarColor, forKey: .calendarColor)
        try container.encode(timeZone, forKey: .timeZone)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(modifiedDate, forKey: .modifiedDate)
        try container.encode(isConflicted, forKey: .isConflicted)
        try container.encodeIfPresent(travelTime, forKey: .travelTime)
    }
    
    /// Duration of the event in hours
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    /// Check if event is happening today
    var isToday: Bool {
        Calendar.current.isDateInToday(startDate)
    }
    
    /// Check if event is in the future
    var isUpcoming: Bool {
        startDate > Date()
    }
    
    /// Check if event is currently happening
    var isHappening: Bool {
        let now = Date()
        return startDate <= now && endDate >= now
    }
    
    /// Get event status text
    var statusText: String {
        if isHappening {
            return "Happening now"
        } else if isUpcoming {
            return "Upcoming"
        } else {
            return "Past"
        }
    }
    
    /// Formatted time range string
    var timeRangeText: String {
        let formatter = DateFormatter()
        if isAllDay {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: startDate)
        } else {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            let start = formatter.string(from: startDate)
            let end = formatter.string(from: endDate)
            return "\(start) - \(end)"
        }
    }
    
    /// Check for conflicts with another event
    func conflictsWith(_ other: CalendarEvent) -> Bool {
        guard !isAllDay && !other.isAllDay else { return false }
        return startDate < other.endDate && endDate > other.startDate
    }
    
    // MARK: - Hashable
    
    static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Search and Filter Models

/// Search scope for events
enum EventSearchScope: String, CaseIterable, Identifiable {
    case all = "All"
    case title = "Title"
    case location = "Location"
    case attendees = "Attendees"
    case notes = "Notes"
    
    var id: String { rawValue }
}

/// Event filter options
struct EventFilter {
    var timeRange: DateInterval?
    var priorities: Set<EventPriority> = Set(EventPriority.allCases)
    var colors: Set<CalendarColor> = Set(CalendarColor.allCases)
    var includeAllDay: Bool = true
    var includeRecurring: Bool = true
    var searchScope: EventSearchScope = .all
    
    func matches(_ event: CalendarEvent, searchText: String = "") -> Bool {
        // Check time range
        if let timeRange = timeRange {
            if !timeRange.contains(event.startDate) && !timeRange.contains(event.endDate) {
                return false
            }
        }
        
        // Check priority
        if !priorities.contains(event.priority) {
            return false
        }
        
        // Check color
        if !colors.contains(event.calendarColor) {
            return false
        }
        
        // Check all-day filter
        if !includeAllDay && event.isAllDay {
            return false
        }
        
        // Check recurring filter
        if !includeRecurring && event.recurrenceRule != .never {
            return false
        }
        
        // Check search text
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            switch searchScope {
            case .all:
                return event.title.lowercased().contains(lowercasedSearch) ||
                       event.notes.lowercased().contains(lowercasedSearch) ||
                       event.location?.name.lowercased().contains(lowercasedSearch) == true ||
                       event.attendees.contains { $0.name.lowercased().contains(lowercasedSearch) }
            case .title:
                return event.title.lowercased().contains(lowercasedSearch)
            case .location:
                return event.location?.name.lowercased().contains(lowercasedSearch) == true
            case .attendees:
                return event.attendees.contains { $0.name.lowercased().contains(lowercasedSearch) }
            case .notes:
                return event.notes.lowercased().contains(lowercasedSearch)
            }
        }
        
        return true
    }
}

// MARK: - Widget and Notification Models

/// Today widget configuration
struct TodayWidgetEntry {
    let date: Date
    let events: [CalendarEvent]
    let nextEvent: CalendarEvent?
    let conflictCount: Int
}

/// Live Activity configuration for Dynamic Island
struct CalendarLiveActivity {
    let currentEvent: CalendarEvent
    let nextEvent: CalendarEvent?
    let timeRemaining: TimeInterval
}

/// Notification action types
enum NotificationAction: String, CaseIterable {
    case snooze = "SNOOZE"
    case view = "VIEW"
    case markAttending = "ATTENDING"
    case markNotAttending = "NOT_ATTENDING"
    
    var title: String {
        switch self {
        case .snooze: return "Snooze"
        case .view: return "View"
        case .markAttending: return "I'm Attending"
        case .markNotAttending: return "Can't Attend"
        }
    }
}

// MARK: - AI Integration Models

/// AI suggestion types
enum AISuggestionType: String, CaseIterable, Identifiable {
    case findTime = "Find Time"
    case smartSchedule = "Smart Schedule"
    case eventSummary = "Event Summary"
    case travelTime = "Travel Time"
    case conflictResolution = "Conflict Resolution"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .findTime: return "clock.badge.questionmark"
        case .smartSchedule: return "brain.head.profile"
        case .eventSummary: return "doc.text.magnifyingglass"
        case .travelTime: return "car.fill"
        case .conflictResolution: return "exclamationmark.triangle.fill"
        }
    }
}

/// AI suggestion model
struct AISuggestion: Identifiable {
    let id = UUID()
    let type: AISuggestionType
    let title: String
    let description: String
    let confidence: Double
    let actionData: [String: Any]
    let relatedEvents: [CalendarEvent]
    
    var confidenceText: String {
        switch confidence {
        case 0.8...1.0: return "High confidence"
        case 0.6..<0.8: return "Medium confidence"
        case 0.4..<0.6: return "Low confidence"
        default: return "Very low confidence"
        }
    }
}

/// Time slot recommendation for AI scheduling
struct TimeSlotRecommendation: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let confidence: Double
    let reason: String
    let conflictingEvents: [CalendarEvent]
    
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    var isOptimal: Bool {
        confidence > 0.8 && conflictingEvents.isEmpty
    }
} 