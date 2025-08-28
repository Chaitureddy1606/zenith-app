import SwiftUI
import MapKit
import Contacts
import EventKit

// MARK: - Apple Event Detail Sheet

/// Comprehensive event detail and editing sheet with Apple HIG compliance
struct AppleEventDetailSheet: View {
    let event: CalendarEvent?
    let calendarManager: CalendarManager
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var editableEvent: CalendarEvent
    @State private var showingLocationPicker = false
    @State private var showingAttendeesPicker = false
    @State private var showingDeleteAlert = false
    @State private var showingRepeatOptions = false
    @State private var showingTimeZonePicker = false
    @State private var newAttendee = EventAttendee(name: "")
    @State private var showingAddAttendee = false
    @State private var showingNotePicker = false
    
    // Form validation
    @State private var titleError: String?
    
    private let isCreating: Bool
    
    init(event: CalendarEvent?, calendarManager: CalendarManager) {
        self.event = event
        self.calendarManager = calendarManager
        self.isCreating = event == nil
        
        if let event = event {
            self._editableEvent = StateObject(wrappedValue: event)
        } else {
            let newEvent = CalendarEvent(
                title: "",
                startDate: calendarManager.selectedTimeSlot ?? Date(),
                endDate: (calendarManager.selectedTimeSlot ?? Date()).addingTimeInterval(3600)
            )
            self._editableEvent = StateObject(wrappedValue: newEvent)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information Section
                basicInfoSection
                
                // Date & Time Section
                dateTimeSection
                
                // Repeat Section
                repeatSection
                
                // Location Section
                locationSection
                
                // Attendees Section
                attendeesSection
                
                // Alerts Section
                alertsSection
                
                // Notes & URL Section
                notesSection
                
                // Advanced Options Section
                advancedSection
                
                // Delete Section (if editing)
                if !isCreating {
                    deleteSection
                }
            }
            .navigationTitle(isCreating ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEvent()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidEvent)
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                AppleLocationPickerSheet(
                    selectedLocation: $editableEvent.location,
                    isPresented: $showingLocationPicker,
                    calendarManager: calendarManager
                )
            }
            .sheet(isPresented: $showingAttendeesPicker) {
                AttendeesPickerSheet(
                    attendees: $editableEvent.attendees,
                    isPresented: $showingAttendeesPicker
                )
            }
            .sheet(isPresented: $showingRepeatOptions) {
                RepeatOptionsSheet(
                    recurrenceRule: $editableEvent.recurrenceRule,
                    customRecurrence: $editableEvent.customRecurrence,
                    isPresented: $showingRepeatOptions
                )
            }
            .sheet(isPresented: $showingTimeZonePicker) {
                TimeZonePickerSheet(
                    selectedTimeZone: $editableEvent.timeZone,
                    isPresented: $showingTimeZonePicker
                )
            }
            .alert("Delete Event", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let event = event {
                        calendarManager.deleteEvent(event)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this event? This action cannot be undone.")
            }
        }
        .onChange(of: editableEvent.startDate) { _, newValue in
            // Ensure end date is after start date
            if editableEvent.endDate <= newValue {
                editableEvent.endDate = newValue.addingTimeInterval(editableEvent.isAllDay ? 86400 : 3600)
            }
        }
        .onChange(of: editableEvent.isAllDay) { _, isAllDay in
            let calendar = Calendar.current
            if isAllDay {
                // Set to start of day
                editableEvent.startDate = calendar.startOfDay(for: editableEvent.startDate)
                editableEvent.endDate = calendar.startOfDay(for: editableEvent.endDate)
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var basicInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Event Title", text: $editableEvent.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .textFieldStyle(.plain)
                
                if let error = titleError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Priority Picker
            Picker("Priority", selection: $editableEvent.priority) {
                ForEach(EventPriority.allCases) { priority in
                    Label(priority.rawValue, systemImage: priority.systemImage)
                        .tag(priority)
                }
            }
            
            // Calendar Color
            Picker("Calendar", selection: $editableEvent.calendarColor) {
                ForEach(CalendarColor.allCases) { color in
                    HStack {
                        Circle()
                            .fill(color.color)
                            .frame(width: 12, height: 12)
                        Text(color.rawValue)
                    }
                    .tag(color)
                }
            }
        }
    }
    
    private var dateTimeSection: some View {
        Section("Date & Time") {
            // Time Zone
            HStack {
                Label("Time Zone", systemImage: "globe")
                Spacer()
                Button(editableEvent.timeZone.abbreviation) {
                    showingTimeZonePicker = true
                }
                .foregroundColor(Color.accentColor)
            }
            
            // All Day Toggle
            Toggle("All Day", isOn: $editableEvent.isAllDay)
            
            if editableEvent.isAllDay {
                // All-day date pickers
                DatePicker("Starts", selection: $editableEvent.startDate, displayedComponents: .date)
                DatePicker("Ends", selection: $editableEvent.endDate, displayedComponents: .date)
            } else {
                // Date and time pickers
                DatePicker("Starts", selection: $editableEvent.startDate)
                DatePicker("Ends", selection: $editableEvent.endDate)
            }
            
            // Travel Time
            if editableEvent.location != nil {
                Picker("Travel Time", selection: Binding(
                    get: { editableEvent.travelTime ?? 0 },
                    set: { editableEvent.travelTime = $0 == 0 ? nil : $0 }
                )) {
                    Text("None").tag(TimeInterval(0))
                    Text("15 minutes").tag(TimeInterval(900))
                    Text("30 minutes").tag(TimeInterval(1800))
                    Text("1 hour").tag(TimeInterval(3600))
                    Text("1.5 hours").tag(TimeInterval(5400))
                    Text("2 hours").tag(TimeInterval(7200))
                }
            }
        }
    }
    
    private var repeatSection: some View {
        Section("Repeat") {
            HStack {
                Label("Repeat", systemImage: "repeat")
                Spacer()
                Button(editableEvent.recurrenceRule.rawValue) {
                    showingRepeatOptions = true
                }
                .foregroundColor(Color.accentColor)
            }
            
            if editableEvent.recurrenceRule != .never {
                if let customRecurrence = editableEvent.customRecurrence {
                    Text(customRecurrence.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var locationSection: some View {
        Section("Location") {
            if let location = editableEvent.location {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(location.name, systemImage: "location.fill")
                        Spacer()
                        Button("Edit") {
                            showingLocationPicker = true
                        }
                        .foregroundColor(Color.accentColor)
                    }
                    
                    if let address = location.address, !address.isEmpty {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Mini map if coordinates available
                    if let coordinate = location.coordinate {
                        Map {
                            Annotation("Event Location", coordinate: coordinate) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                            }
                        }
                        .frame(height: 120)
                        .cornerRadius(8)
                        .allowsHitTesting(false)
                    }
                }
            } else {
                Button(action: { showingLocationPicker = true }) {
                    Label("Add Location", systemImage: "location")
                        .foregroundColor(Color.accentColor)
                }
            }
        }
    }
    
    private var attendeesSection: some View {
        Section("Attendees") {
            if editableEvent.attendees.isEmpty {
                Button(action: { showingAttendeesPicker = true }) {
                    Label("Add People", systemImage: "person.badge.plus")
                        .foregroundColor(Color.accentColor)
                }
            } else {
                ForEach(editableEvent.attendees) { attendee in
                    AttendeeRow(attendee: attendee)
                }
                .onDelete(perform: deleteAttendee)
                
                Button(action: { showingAttendeesPicker = true }) {
                    Label("Add People", systemImage: "person.badge.plus")
                        .foregroundColor(Color.accentColor)
                }
            }
        }
    }
    
    private var alertsSection: some View {
        Section("Alerts") {
            if editableEvent.alerts.isEmpty {
                Button(action: addAlert) {
                    Label("Add Alert", systemImage: "bell.badge.plus")
                        .foregroundColor(Color.accentColor)
                }
            } else {
                ForEach(editableEvent.alerts) { alert in
                    AlertRow(alert: alert, event: editableEvent)
                }
                .onDelete(perform: deleteAlert)
                
                Button(action: addAlert) {
                    Label("Add Alert", systemImage: "bell.badge.plus")
                        .foregroundColor(Color.accentColor)
                }
            }
        }
    }
    
    private var notesSection: some View {
        Section("Notes & URL") {
            VStack(alignment: .leading, spacing: 12) {
                if !editableEvent.notes.isEmpty || editableEvent.notes.isEmpty {
                    Text("Notes")
                        .font(.headline)
                    
                    TextEditor(text: $editableEvent.notes)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                }
                
                HStack {
                    Text("URL")
                        .font(.headline)
                    TextField("https://", text: Binding(
                        get: { editableEvent.url ?? "" },
                        set: { editableEvent.url = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                }
            }
        }
    }
    
    private var advancedSection: some View {
        Section("Advanced") {
            // Show as Busy/Free
            Picker("Show As", selection: Binding(
                get: { editableEvent.priority },
                set: { editableEvent.priority = $0 }
            )) {
                Text("Busy").tag(EventPriority.medium)
                Text("Free").tag(EventPriority.low)
            }
            
            // Private Event Toggle
            HStack {
                Label("Private", systemImage: "lock.fill")
                Spacer()
                // This would be a published property on CalendarEvent in a real implementation
                Toggle("", isOn: .constant(false))
                    .labelsHidden()
            }
        }
    }
    
    private var deleteSection: some View {
        Section {
            Button("Delete Event") {
                showingDeleteAlert = true
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    // MARK: - Helper Methods
    
    private var isValidEvent: Bool {
        !editableEvent.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveEvent() {
        // Validate title
        let trimmedTitle = editableEvent.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            titleError = "Title is required"
            return
        }
        
        titleError = nil
        editableEvent.title = trimmedTitle
        
        if isCreating {
            calendarManager.addEvent(editableEvent)
        } else {
            calendarManager.updateEvent(editableEvent)
        }
        
        // Haptic feedback
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.success)
        
        dismiss()
    }
    
    private func deleteAttendee(at offsets: IndexSet) {
        editableEvent.attendees.remove(atOffsets: offsets)
    }
    
    private func addAlert() {
        let newAlert = EventAlert(timing: .fifteenMin)
        editableEvent.alerts.append(newAlert)
    }
    
    private func deleteAlert(at offsets: IndexSet) {
        editableEvent.alerts.remove(atOffsets: offsets)
    }
}

// MARK: - Supporting Views

struct AttendeeRow: View {
    let attendee: EventAttendee
    
    var body: some View {
        HStack {
            // Response status icon
            Image(systemName: attendee.response.systemImage)
                .foregroundColor(attendee.response.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(attendee.displayName)
                    .fontWeight(attendee.isOrganizer ? .semibold : .regular)
                
                if let email = attendee.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(attendee.response.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(attendee.response.color.opacity(0.1), in: Capsule())
        }
    }
}

struct AlertRow: View {
    let alert: EventAlert
    let event: CalendarEvent
    
    var body: some View {
        HStack {
            Image(systemName: "bell.fill")
                .foregroundColor(Color.accentColor)
                .frame(width: 20)
            
            Text(alert.displayText)
            
            Spacer()
            
            if alert.timing == .custom {
                Text("Custom")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Location Picker Sheet

struct AppleLocationPickerSheet: View {
    @Binding var selectedLocation: EventLocation?
    @Binding var isPresented: Bool
    let calendarManager: CalendarManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var locationName = ""
    @State private var locationAddress = ""
    @State private var useCurrentLocation = false
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Search section
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Location name", text: $locationName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Address (optional)", text: $locationAddress)
                        .textFieldStyle(.roundedBorder)
                    
                    // Current location button
                    Button(action: useCurrentLocationAction) {
                        Label("Use Current Location", systemImage: "location.fill")
                            .foregroundColor(Color.accentColor)
                    }
                    .disabled(!calendarManager.isLocationAuthorized)
                }
                .padding()
                
                // Map view
                Map {
                    // Empty map content - just showing the region
                }
                .frame(height: 300)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Search results
                if !searchResults.isEmpty {
                    List(searchResults, id: \.self) { mapItem in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mapItem.name ?? "Unknown")
                                .fontWeight(.medium)
                            
                            if let address = mapItem.placemark.title {
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onTapGesture {
                            selectMapItem(mapItem)
                        }
                    }
                    .frame(maxHeight: 200)
                }
                
                Spacer()
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLocation()
                    }
                    .disabled(locationName.isEmpty)
                }
            }
            .onAppear {
                if let location = selectedLocation {
                    locationName = location.name
                    locationAddress = location.address ?? ""
                    
                    if let coordinate = location.coordinate {
                        mapRegion.center = coordinate
                    }
                }
            }
            .onChange(of: locationName) { _, newValue in
                if !newValue.isEmpty {
                    searchLocations(query: newValue)
                }
            }
        }
    }
    
    private func useCurrentLocationAction() {
        if let currentLocation = calendarManager.getCurrentLocation() {
            mapRegion.center = currentLocation.coordinate
            locationName = "Current Location"
            useCurrentLocation = true
            
            // Reverse geocoding would go here in a real implementation
            locationAddress = "Your current location"
        }
    }
    
    private func searchLocations(query: String) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        searchRequest.region = mapRegion
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            if let response = response {
                searchResults = Array(response.mapItems.prefix(5))
            }
        }
    }
    
    private func selectMapItem(_ mapItem: MKMapItem) {
        locationName = mapItem.name ?? ""
        locationAddress = mapItem.placemark.title ?? ""
        mapRegion.center = mapItem.placemark.coordinate
        searchResults = []
    }
    
    private func saveLocation() {
        let location = EventLocation(
            name: locationName,
            address: locationAddress.isEmpty ? nil : locationAddress,
            latitude: mapRegion.center.latitude,
            longitude: mapRegion.center.longitude,
            isCurrentLocation: useCurrentLocation
        )
        
        selectedLocation = location
        dismiss()
    }
}

// MARK: - Attendees Picker Sheet

struct AttendeesPickerSheet: View {
    @Binding var attendees: [EventAttendee]
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var newAttendeeName = ""
    @State private var newAttendeeEmail = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Add new attendee section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add Attendee")
                        .font(.headline)
                    
                    TextField("Name", text: $newAttendeeName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Email (optional)", text: $newAttendeeEmail)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Button("Add") {
                        addAttendee()
                    }
                    .disabled(newAttendeeName.isEmpty)
                }
                .padding()
                
                // Current attendees list
                if !attendees.isEmpty {
                    List {
                        ForEach(attendees) { attendee in
                            AttendeeRow(attendee: attendee)
                        }
                        .onDelete(perform: deleteAttendee)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Attendees")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addAttendee() {
        let newAttendee = EventAttendee(
            name: newAttendeeName,
            email: newAttendeeEmail.isEmpty ? nil : newAttendeeEmail
        )
        attendees.append(newAttendee)
        
        newAttendeeName = ""
        newAttendeeEmail = ""
    }
    
    private func deleteAttendee(at offsets: IndexSet) {
        attendees.remove(atOffsets: offsets)
    }
}

// MARK: - Repeat Options Sheet

struct RepeatOptionsSheet: View {
    @Binding var recurrenceRule: RecurrenceRule
    @Binding var customRecurrence: CustomRecurrenceRule?
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingCustomOptions = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(RecurrenceRule.allCases) { rule in
                    HStack {
                        Text(rule.rawValue)
                        Spacer()
                        if recurrenceRule == rule {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        recurrenceRule = rule
                        if rule == .custom {
                            showingCustomOptions = true
                        } else {
                            customRecurrence = nil
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Repeat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCustomOptions) {
                CustomRecurrenceSheet(
                    customRecurrence: $customRecurrence,
                    isPresented: $showingCustomOptions
                )
            }
        }
    }
}

// MARK: - Custom Recurrence Sheet

struct CustomRecurrenceSheet: View {
    @Binding var customRecurrence: CustomRecurrenceRule?
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var frequency: EKRecurrenceFrequency = .weekly
    @State private var interval = 1
    @State private var selectedDays: Set<Int> = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Frequency") {
                    Picker("Repeat", selection: $frequency) {
                        Text("Daily").tag(EKRecurrenceFrequency.daily)
                        Text("Weekly").tag(EKRecurrenceFrequency.weekly)
                        Text("Monthly").tag(EKRecurrenceFrequency.monthly)
                        Text("Yearly").tag(EKRecurrenceFrequency.yearly)
                    }
                    .pickerStyle(.segmented)
                    
                    Stepper("Every \(interval) \(frequencyUnit)", value: $interval, in: 1...999)
                }
                
                if frequency == .weekly {
                    Section("Repeat On") {
                        ForEach(0..<7) { dayIndex in
                            let weekday = Calendar.current.weekdaySymbols[dayIndex]
                            Toggle(weekday, isOn: Binding(
                                get: { selectedDays.contains(dayIndex + 1) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedDays.insert(dayIndex + 1)
                                    } else {
                                        selectedDays.remove(dayIndex + 1)
                                    }
                                }
                            ))
                        }
                    }
                }
            }
            .navigationTitle("Custom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCustomRecurrence()
                    }
                }
            }
        }
    }
    
    private var frequencyUnit: String {
        switch frequency {
        case .daily: return interval == 1 ? "day" : "days"
        case .weekly: return interval == 1 ? "week" : "weeks"
        case .monthly: return interval == 1 ? "month" : "months"
        case .yearly: return interval == 1 ? "year" : "years"
        @unknown default: return "period"
        }
    }
    
    private func saveCustomRecurrence() {
        var newCustomRecurrence = CustomRecurrenceRule()
        newCustomRecurrence.frequency = frequency
        newCustomRecurrence.interval = interval
        
        if frequency == .weekly && !selectedDays.isEmpty {
            newCustomRecurrence.daysOfWeek = selectedDays.map { dayNumber in
                EKRecurrenceDayOfWeek(dayOfTheWeek: EKWeekday(rawValue: dayNumber)!, weekNumber: 0)
            }
        }
        
        customRecurrence = newCustomRecurrence
        dismiss()
    }
}

// MARK: - Time Zone Picker Sheet

struct TimeZonePickerSheet: View {
    @Binding var selectedTimeZone: EventTimeZone
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    
    private var commonTimeZones: [EventTimeZone] {
        [
            EventTimeZone.current,
            EventTimeZone.utc,
            EventTimeZone(identifier: "America/New_York", displayName: "Eastern Time", abbreviation: "ET"),
            EventTimeZone(identifier: "America/Chicago", displayName: "Central Time", abbreviation: "CT"),
            EventTimeZone(identifier: "America/Denver", displayName: "Mountain Time", abbreviation: "MT"),
            EventTimeZone(identifier: "America/Los_Angeles", displayName: "Pacific Time", abbreviation: "PT"),
            EventTimeZone(identifier: "Europe/London", displayName: "London", abbreviation: "GMT"),
            EventTimeZone(identifier: "Europe/Paris", displayName: "Paris", abbreviation: "CET"),
            EventTimeZone(identifier: "Asia/Tokyo", displayName: "Tokyo", abbreviation: "JST")
        ]
    }
    
    private var filteredTimeZones: [EventTimeZone] {
        if searchText.isEmpty {
            return commonTimeZones
        } else {
            return commonTimeZones.filter { timeZone in
                timeZone.displayName.localizedCaseInsensitiveContains(searchText) ||
                timeZone.abbreviation.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredTimeZones, id: \.identifier) { timeZone in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(timeZone.displayName)
                                .fontWeight(.medium)
                            Text(timeZone.abbreviation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedTimeZone.identifier == timeZone.identifier {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTimeZone = timeZone
                        dismiss()
                    }
                }
            }
            .navigationTitle("Time Zone")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search time zones")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 