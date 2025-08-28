import SwiftUI
import MapKit

// MARK: - Main Apple-Grade Calendar View

/// Production-ready Calendar & Event Management screen with Apple HIG compliance
struct AppleCalendarView: View {
    @StateObject private var calendarManager = CalendarManager()
    @State private var showingEventDetail: CalendarEvent?
    @State private var showingAddEvent = false
    @State private var draggedTask: Task?
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content based on view mode
                mainCalendarContent
                
                // Floating "Today" button for week/month views
                if calendarManager.viewMode != .day {
                    todayFloatingButton
                }
                
                // AI Find Time FAB for day view
                if calendarManager.viewMode == .day {
                    findTimeFAB
                }
                
                // Conflict warning banner
                if !calendarManager.conflictingEvents.isEmpty {
                    conflictWarningBanner
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $calendarManager.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search events"
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Jump to Date", systemImage: "calendar.badge.clock") {
                            calendarManager.showingJumpToDate = true
                        }
                        
                        Divider()
                        
                        Button("Add Event", systemImage: "plus.circle") {
                            showingAddEvent = true
                        }
                        
                        if !calendarManager.aiSuggestions.isEmpty {
                            Divider()
                            
                            ForEach(calendarManager.aiSuggestions) { suggestion in
                                Button(suggestion.title, systemImage: suggestion.type.systemImage) {
                                    // Handle AI suggestion
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .accessibilityLabel("Calendar options")
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                // View mode segmented control
                viewModeSegmentedControl
            }
            .sheet(isPresented: $showingAddEvent) {
                AppleEventDetailSheet(
                    event: nil,
                    calendarManager: calendarManager
                )
            }
            .sheet(item: $showingEventDetail) { event in
                AppleEventDetailSheet(
                    event: event,
                    calendarManager: calendarManager
                )
            }
            .sheet(isPresented: $calendarManager.showingJumpToDate) {
                JumpToDateSheet(calendarManager: calendarManager)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .tint(.accentColor)
        .onChange(of: calendarManager.viewMode) { _, _ in
            // Haptic feedback on view mode change
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    // MARK: - Main Content Views
    
    @ViewBuilder
    private var mainCalendarContent: some View {
        switch calendarManager.viewMode {
        case .day:
            AppleDayView(calendarManager: calendarManager, showingEventDetail: $showingEventDetail)
        case .week:
            AppleWeekView(calendarManager: calendarManager, showingEventDetail: $showingEventDetail)
        case .month:
            AppleMonthView(calendarManager: calendarManager, showingEventDetail: $showingEventDetail)
        case .year:
            AppleYearView(calendarManager: calendarManager, showingEventDetail: $showingEventDetail)
        }
    }
    
    // MARK: - View Mode Segmented Control
    
    private var viewModeSegmentedControl: some View {
        VStack(spacing: 0) {
            HStack {
                // Navigation buttons
                Button(action: { calendarManager.goToPrevious() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Previous period")
                
                Spacer()
                
                // Current date display
                Text(currentDateText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .animation(.spring(), value: calendarManager.currentDate)
                
                Spacer()
                
                Button(action: { calendarManager.goToNext() }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Next period")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Segmented control
            Picker("View Mode", selection: $calendarManager.viewMode) {
                ForEach(CalendarViewMode.allCases) { mode in
                    Text(mode.rawValue)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(.regularMaterial, in: Rectangle())
    }
    
    // MARK: - Floating Action Buttons
    
    private var todayFloatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button("Today") {
                    withAnimation(.spring()) {
                        calendarManager.goToToday()
                    }
                    
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .accessibilityLabel("Go to today")
            }
            .padding()
        }
    }
    
    private var findTimeFAB: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Today button
                    Button("Today") {
                        withAnimation(.spring()) {
                            calendarManager.goToToday()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    
                    // Find Time FAB
                    Button(action: {
                        // Handle find time AI suggestion
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.accentColor, in: Circle())
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .accessibilityLabel("Find available time")
                }
            }
            .padding()
        }
    }
    
    // MARK: - Conflict Warning Banner
    
    private var conflictWarningBanner: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("Schedule conflicts detected")
                    .font(.footnote)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Review") {
                    // Handle conflict review
                }
                .font(.footnote)
                .foregroundColor(Color.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 8)
    }
    
    // MARK: - Computed Properties
    
    private var currentDateText: String {
        let formatter = DateFormatter()
        
        switch calendarManager.viewMode {
        case .day:
            formatter.dateFormat = "EEEE, MMMM d"
        case .week:
            let calendar = Calendar.current
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: calendarManager.currentDate) else {
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: calendarManager.currentDate)
            }
            
            let startFormatter = DateFormatter()
            startFormatter.dateFormat = "MMM d"
            let endFormatter = DateFormatter()
            endFormatter.dateFormat = "MMM d, yyyy"
            
            return "\(startFormatter.string(from: weekInterval.start)) – \(endFormatter.string(from: weekInterval.end.addingTimeInterval(-1)))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        case .year:
            formatter.dateFormat = "yyyy"
        }
        
        return formatter.string(from: calendarManager.currentDate)
    }
}

// MARK: - Apple Day View

struct AppleDayView: View {
    @ObservedObject var calendarManager: CalendarManager
    @Binding var showingEventDetail: CalendarEvent?
    
    private let hours = Array(0...23)
    private let hourHeight: CGFloat = 60
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(hours, id: \.self) { hour in
                        HourSlotView(
                            hour: hour,
                            date: calendarManager.selectedDate,
                            events: calendarManager.events(for: calendarManager.selectedDate, hour: hour),
                            calendarManager: calendarManager,
                            showingEventDetail: $showingEventDetail
                        )
                        .frame(height: hourHeight)
                        .id(hour)
                    }
                }
            }
            .onAppear {
                // Scroll to current hour
                let currentHour = Calendar.current.component(.hour, from: Date())
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo(max(0, currentHour - 2), anchor: .top)
                }
            }
        }
    }
}

// MARK: - Hour Slot View

struct HourSlotView: View {
    let hour: Int
    let date: Date
    let events: [CalendarEvent]
    @ObservedObject var calendarManager: CalendarManager
    @Binding var showingEventDetail: CalendarEvent?
    
    @State private var isTargeted = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Time label
            VStack {
                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
                
                Spacer()
            }
            .padding(.trailing, 8)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
            
            // Event area
            ZStack(alignment: .topLeading) {
                // Drop target
                Rectangle()
                    .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
                    .overlay(
                        Rectangle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    )
                    .onTapGesture {
                        // Create new event at this time
                        let eventStart = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
                        calendarManager.selectedTimeSlot = eventStart
                        showingEventDetail = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            calendarManager.showingAddEvent = true
                        }
                    }
                    // TODO: Re-enable drag and drop when Task conforms to Transferable
                    // .dropDestination(for: Task.self) { droppedTasks, location in
                    //     // Handle task drop
                    //     for task in droppedTasks {
                    //         let eventStart = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
                    //         calendarManager.createEventFromTask(task, at: eventStart)
                    //     }
                    //     isTargeted = false
                    //     return true
                    // } isTargeted: { targeted in
                    //     isTargeted = targeted
                    // }
                
                // Events
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    AppleEventBlock(
                        event: event,
                        isCompact: false,
                        indentLevel: index
                    )
                    .onTapGesture {
                        showingEventDetail = event
                        
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
            }
            .padding(.leading, 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(timeString), \(events.count) events")
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Apple Week View

struct AppleWeekView: View {
    @ObservedObject var calendarManager: CalendarManager
    @Binding var showingEventDetail: CalendarEvent?
    
    private let calendar = Calendar.current
    private let hours = Array(0...23)
    private let hourHeight: CGFloat = 50
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // All-day events section
                if hasAllDayEvents {
                    allDayEventsSection
                        .padding(.bottom, 8)
                }
                
                // Week grid
                HStack(spacing: 0) {
                    // Time column
                    timeColumn
                    
                    // Day columns
                    ForEach(weekDays, id: \.self) { date in
                        WeekDayColumn(
                            date: date,
                            hours: hours,
                            hourHeight: hourHeight,
                            calendarManager: calendarManager,
                            showingEventDetail: $showingEventDetail
                        )
                    }
                }
            }
        }
    }
    
    private var timeColumn: some View {
        VStack(spacing: 0) {
            // Header space
            Rectangle()
                .fill(Color.clear)
                .frame(height: 40)
            
            // Hour labels
            ForEach(hours, id: \.self) { hour in
                VStack {
                    Text(hourString(for: hour))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .frame(height: hourHeight)
            }
        }
        .frame(width: 50)
    }
    
    private var allDayEventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All Day")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 58)
            
            HStack(spacing: 0) {
                // Time column spacer
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 50)
                
                // All-day events for each day
                ForEach(weekDays, id: \.self) { date in
                    VStack(spacing: 4) {
                        ForEach(allDayEvents(for: date)) { event in
                            AppleEventBlock(event: event, isCompact: true)
                                .onTapGesture {
                                    showingEventDetail = event
                                }
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    private var weekDays: [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: calendarManager.selectedDate) else {
            return []
        }
        
        var days: [Date] = []
        var currentDate = weekInterval.start
        
        while currentDate < weekInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private var hasAllDayEvents: Bool {
        weekDays.contains { date in
            !allDayEvents(for: date).isEmpty
        }
    }
    
    private func allDayEvents(for date: Date) -> [CalendarEvent] {
        calendarManager.events(for: date).filter { $0.isAllDay }
    }
    
    private func hourString(for hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Week Day Column

struct WeekDayColumn: View {
    let date: Date
    let hours: [Int]
    let hourHeight: CGFloat
    @ObservedObject var calendarManager: CalendarManager
    @Binding var showingEventDetail: CalendarEvent?
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // Day header
            VStack(spacing: 4) {
                Text(dayOfWeekString)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(isToday ? .bold : .medium)
                    .foregroundColor(isToday ? .white : .primary)
                    .frame(width: 28, height: 28)
                    .background(isToday ? Color.accentColor : .clear, in: Circle())
            }
            .frame(height: 40)
            
            // Hour slots
            ForEach(hours, id: \.self) { hour in
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color.clear)
                        .overlay(
                            Rectangle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        )
                    
                    // Events for this hour
                    let hourEvents = calendarManager.events(for: date, hour: hour).filter { !$0.isAllDay }
                    ForEach(Array(hourEvents.enumerated()), id: \.element.id) { index, event in
                        AppleEventBlock(
                            event: event,
                            isCompact: true,
                            indentLevel: index
                        )
                        .onTapGesture {
                            showingEventDetail = event
                        }
                    }
                }
                .frame(height: hourHeight)
                .onTapGesture {
                    let eventStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
                    calendarManager.selectedTimeSlot = eventStart
                    showingEventDetail = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        calendarManager.showingAddEvent = true
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var isToday: Bool {
        calendar.isDate(date, inSameDayAs: Date())
    }
    
    private var dayOfWeekString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
}

// MARK: - Apple Month View

struct AppleMonthView: View {
    @ObservedObject var calendarManager: CalendarManager
    @Binding var showingEventDetail: CalendarEvent?
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 1) {
                // Day headers
                ForEach(dayHeaders, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                }
                
                // Month days
                ForEach(monthDays, id: \.self) { date in
                    AppleMonthDayCell(
                        date: date,
                        events: calendarManager.events(for: date),
                        isSelected: calendar.isDate(date, inSameDayAs: calendarManager.selectedDate),
                        isToday: calendar.isDate(date, inSameDayAs: Date()),
                        isInCurrentMonth: calendar.isDate(date, equalTo: calendarManager.selectedDate, toGranularity: .month)
                    )
                    .onTapGesture {
                        withAnimation(.spring()) {
                            calendarManager.selectedDate = date
                            calendarManager.viewMode = .day
                        }
                        
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    private var dayHeaders: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }
    
    private var monthDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: calendarManager.selectedDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end.addingTimeInterval(-1)) else {
            return []
        }
        
        var days: [Date] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate < monthLastWeek.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
}

// MARK: - Month Day Cell

struct AppleMonthDayCell: View {
    let date: Date
    let events: [CalendarEvent]
    let isSelected: Bool
    let isToday: Bool
    let isInCurrentMonth: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 2) {
            // Day number
            Text("\(calendar.component(.day, from: date))")
                .font(.body)
                .fontWeight(isToday ? .bold : .medium)
                .foregroundColor(textColor)
                .frame(width: 28, height: 28)
                .background(backgroundShape)
            
            // Event indicators
            HStack(spacing: 2) {
                ForEach(Array(events.prefix(3).enumerated()), id: \.element.id) { index, event in
                    Circle()
                        .fill(event.calendarColor.color)
                        .frame(width: 4, height: 4)
                }
                
                if events.count > 3 {
                    Text("+")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .frame(height: 8)
            
            Spacer()
        }
        .frame(height: 60)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }
    
    @ViewBuilder
    private var backgroundShape: some View {
        if isToday {
            Circle()
                .fill(Color.accentColor)
        } else if isSelected {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
        } else {
            Color.clear
        }
    }
    
    private var textColor: Color {
        if isToday {
            return .white
        } else if !isInCurrentMonth {
            return .secondary
        } else {
            return .primary
        }
    }
    
    private var accessibilityText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateText = formatter.string(from: date)
        
        if events.isEmpty {
            return dateText
        } else {
            return "\(dateText), \(events.count) events"
        }
    }
}

// MARK: - Apple Year View

struct AppleYearView: View {
    @ObservedObject var calendarManager: CalendarManager
    @Binding var showingEventDetail: CalendarEvent?
    @Namespace private var yearAnimation
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 3)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(yearMonths, id: \.self) { monthDate in
                    YearMonthView(
                        monthDate: monthDate,
                        calendarManager: calendarManager,
                        yearAnimation: yearAnimation
                    )
                    .onTapGesture {
                        withAnimation(.spring()) {
                            calendarManager.selectedDate = monthDate
                            calendarManager.viewMode = .month
                        }
                        
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
                }
            }
            .padding()
        }
    }
    
    private var yearMonths: [Date] {
        let year = calendar.component(.year, from: calendarManager.selectedDate)
        var months: [Date] = []
        
        for month in 1...12 {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) {
                months.append(date)
            }
        }
        
        return months
    }
}

// MARK: - Year Month View

struct YearMonthView: View {
    let monthDate: Date
    @ObservedObject var calendarManager: CalendarManager
    let yearAnimation: Namespace.ID
    
    private let calendar = Calendar.current
    private let miniColumns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    
    var body: some View {
        VStack(spacing: 8) {
            // Month name
            Text(monthName)
                .font(.headline)
                .fontWeight(.semibold)
            
            // Mini calendar grid
            LazyVGrid(columns: miniColumns, spacing: 2) {
                ForEach(monthDays, id: \.self) { date in
                    if calendar.isDate(date, equalTo: monthDate, toGranularity: .month) {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.caption2)
                            .foregroundColor(dayTextColor(for: date))
                            .frame(width: 20, height: 20)
                            .background(dayBackground(for: date))
                    } else {
                        Color.clear
                            .frame(width: 20, height: 20)
                    }
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .matchedGeometryEffect(id: monthDate, in: yearAnimation)
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: monthDate)
    }
    
    private var monthDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date] = []
        var currentDate = monthFirstWeek.start
        let endDate = monthInterval.end
        
        while currentDate < endDate {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private func dayTextColor(for date: Date) -> Color {
        if calendar.isDate(date, inSameDayAs: Date()) {
            return .white
        } else if hasEvents(for: date) {
            return Color.accentColor
        } else {
            return .primary
        }
    }
    
    @ViewBuilder
    private func dayBackground(for date: Date) -> some View {
        if calendar.isDate(date, inSameDayAs: Date()) {
            Circle()
                .fill(Color.accentColor)
        } else {
            Color.clear
        }
    }
    
    private func hasEvents(for date: Date) -> Bool {
        !calendarManager.events(for: date).isEmpty
    }
}

// MARK: - Apple Event Block

struct AppleEventBlock: View {
    let event: CalendarEvent
    var isCompact: Bool = false
    var indentLevel: Int = 0
    
    var body: some View {
        HStack(spacing: 6) {
            // Color indicator
            Rectangle()
                .fill(event.calendarColor.color)
                .frame(width: 3)
            
            VStack(alignment: .leading, spacing: 2) {
                // Title
                Text(event.title)
                    .font(isCompact ? .caption : .footnote)
                    .fontWeight(.medium)
                    .lineLimit(isCompact ? 1 : 2)
                    .foregroundColor(.primary)
                
                if !isCompact && !event.isAllDay {
                    // Time
                    Text(event.timeRangeText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if !isCompact && event.location != nil {
                    // Location
                    HStack(spacing: 2) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(event.location?.name ?? "")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer(minLength: 0)
            
            if event.isConflicted {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, isCompact ? 4 : 6)
        .background(event.calendarColor.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(event.calendarColor.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.leading, CGFloat(indentLevel * 4))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }
    
    private var accessibilityText: String {
        var text = event.title
        if !event.isAllDay {
            text += ", \(event.timeRangeText)"
        }
        if let location = event.location {
            text += ", at \(location.name)"
        }
        if event.isConflicted {
            text += ", has conflicts"
        }
        return text
    }
}

// MARK: - Jump to Date Sheet

struct JumpToDateSheet: View {
    @ObservedObject var calendarManager: CalendarManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Jump to Date")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                DatePicker(
                    "Select date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                
                Button("Go to Date") {
                    calendarManager.jumpToDate(selectedDate)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            selectedDate = calendarManager.selectedDate
        }
    }
} 