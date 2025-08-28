//
//  TasksViews.swift
//  app-ai
//
//  Created by chaitu on 27/08/25.
//

import SwiftUI
import MapKit
import AVFoundation

// MARK: - Enhanced Tasks Management View

/// Enhanced Tasks management view with Universal Inbox
struct EnhancedTasksView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var showingAddTask = false
    @State private var showingTaskDetail: Task?
    @State private var selectedTask: Task?
    @State private var showingRescheduleSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                mainContent
                
                // Floating Add Task Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addTaskButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Account for tab bar
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    searchButton
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddEditTaskSheet(taskManager: taskManager)
            }
            .sheet(item: $showingTaskDetail) { task in
                AddEditTaskSheet(taskManager: taskManager, task: task)
            }
            .sheet(isPresented: $showingRescheduleSheet) {
                if let task = selectedTask {
                    RescheduleTaskSheet(task: task, taskManager: taskManager)
                }
            }
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            // View Mode Picker
            viewModePicker
            
            // Search Bar (when in search mode)
            if taskManager.viewMode == .search {
                searchBar
            }
            
            // Task List Content
            taskListContent
        }
    }
    
    // MARK: - View Mode Picker
    
    private var viewModePicker: some View {
        Picker("View Mode", selection: $taskManager.viewMode) {
            ForEach(TaskManager.ViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search tasks, tags, or locations...", text: $taskManager.searchText)
                .textFieldStyle(.plain)
            
            if !taskManager.searchText.isEmpty {
                Button("Clear") {
                    taskManager.clearSearch()
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Task List Content
    
    @ViewBuilder
    private var taskListContent: some View {
        if taskManager.viewMode == .history {
            historyView
        } else {
            inboxView
        }
    }
    
    // MARK: - Inbox View
    
    private var inboxView: some View {
        List {
            ForEach(taskManager.filteredTasks) { task in
                TaskRowView(
                    task: task,
                    onComplete: {
                        taskManager.toggleTaskCompletion(task)
                    },
                    onReschedule: {
                        selectedTask = task
                        showingRescheduleSheet = true
                    },
                    onEdit: {
                        showingTaskDetail = task
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteTasks)
        }
        .listStyle(.plain)
        .refreshable {
            // Refresh tasks if needed
        }
    }
    
    // MARK: - History View
    
    private var historyView: some View {
        List {
            ForEach(taskManager.groupedHistoryTasks, id: \.0) { date, tasks in
                Section(header: historyHeader(date)) {
                    ForEach(tasks) { task in
                        CompletedTaskRowView(task: task) {
                            showingTaskDetail = task
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func historyHeader(_ date: String) -> some View {
        Text(date)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
            .padding(.vertical, 4)
    }
    
    // MARK: - Floating Add Button
    
    private var addTaskButton: some View {
        Button(action: {
            showingAddTask = true
        }) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("Add new task")
        .accessibilityHint("Opens a form to create a new task")
    }
    
    // MARK: - Search Button
    
    private var searchButton: some View {
        Button(action: {
            if taskManager.viewMode == .search {
                taskManager.clearSearch()
            } else {
                taskManager.viewMode = .search
            }
        }) {
            Image(systemName: taskManager.viewMode == .search ? "xmark" : "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
        }
        .accessibilityLabel(taskManager.viewMode == .search ? "Close search" : "Search tasks")
    }
    
    // MARK: - Helper Methods
    
    private func deleteTasks(offsets: IndexSet) {
        for index in offsets {
            let task = taskManager.filteredTasks[index]
            taskManager.deleteTask(task)
        }
    }
}

// MARK: - Task Row View

/// Individual task row with swipe actions and detailed display
struct TaskRowView: View {
    @ObservedObject var task: Task
    let onComplete: () -> Void
    let onReschedule: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main task content
            HStack(alignment: .top, spacing: 12) {
                // Priority indicator
                priorityDot
                
                // Task details
                VStack(alignment: .leading, spacing: 4) {
                    taskTitle
                    taskMetadata
                    if !task.subTasks.isEmpty {
                        subTaskProgress
                    }
                    if !task.tags.isEmpty {
                        tagBadges
                    }
                }
                
                Spacer()
                
                // Status indicators
                statusIndicators
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(taskBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            completeAction
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            rescheduleAction
        }
        .onTapGesture {
            onEdit()
        }
    }
    
    // MARK: - Task Components
    
    private var priorityDot: some View {
        Circle()
            .fill(task.priority.color)
            .frame(width: 8, height: 8)
            .padding(.top, 6)
    }
    
    private var taskTitle: some View {
        Text(task.title)
            .font(.headline)
            .fontWeight(.medium)
            .foregroundColor(task.isCompleted ? .secondary : .primary)
            .strikethrough(task.isCompleted)
    }
    
    private var taskMetadata: some View {
        HStack(spacing: 8) {
            if let dueDate = task.dueDate {
                dueDateLabel(dueDate)
            }
            
            if task.hasLocation {
                locationIndicator
            }
            
            if task.hasAttachments {
                attachmentIndicator
            }
        }
    }
    
    private func dueDateLabel(_ date: Date) -> some View {
        Text(formatDueDate(date))
            .font(.subheadline)
            .foregroundColor(task.isOverdue ? .red : .secondary)
            .fontWeight(task.isOverdue ? .medium : .regular)
    }
    
    private var locationIndicator: some View {
        Image(systemName: "location.fill")
            .font(.caption)
            .foregroundColor(.blue)
    }
    
    private var attachmentIndicator: some View {
        Image(systemName: "paperclip")
            .font(.caption)
            .foregroundColor(.orange)
    }
    
    private var subTaskProgress: some View {
        HStack(spacing: 8) {
            ProgressView(value: task.subTasksProgress)
                .progressViewStyle(.linear)
                .frame(width: 60)
            
            Text("\(task.completedSubTasksCount)/\(task.subTasks.count)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var tagBadges: some View {
        HStack(spacing: 6) {
            ForEach(Array(task.tags).prefix(3), id: \.self) { tag in
                Text(tag.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tag.color.opacity(0.2))
                    .foregroundColor(tag.color)
                    .clipShape(Capsule())
            }
            
            if task.tags.count > 3 {
                Text("+\(task.tags.count - 3)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var statusIndicators: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if task.reminderEnabled {
                Image(systemName: "bell.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            if task.isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var taskBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(task.isOverdue ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
            )
    }
    
    // MARK: - Swipe Actions
    
    private var completeAction: some View {
        Button(action: onComplete) {
            Label("Complete", systemImage: "checkmark")
        }
        .tint(.green)
    }
    
    private var rescheduleAction: some View {
        Button(action: onReschedule) {
            Label("Reschedule", systemImage: "calendar")
        }
        .tint(.blue)
    }
    
    // MARK: - Helper Methods
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDate(date, inSameDayAs: Date()) {
            formatter.timeStyle = .short
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()) {
            formatter.timeStyle = .short
            return "Tomorrow \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Completed Task Row View

/// Simplified row view for completed tasks in history
struct CompletedTaskRowView: View {
    let task: Task
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .strikethrough()
                
                if let completedDate = task.completedAt {
                    Text("Completed \(formatCompletedTime(completedDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if !task.tags.isEmpty {
                Text(task.tags.first?.rawValue ?? "")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(task.tags.first?.color.opacity(0.2) ?? Color.gray.opacity(0.2))
                    .foregroundColor(task.tags.first?.color ?? .gray)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatCompletedTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Add/Edit Task Sheet

/// Comprehensive task creation and editing sheet
struct AddEditTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskManager: TaskManager
    
    // Task data
    @State private var task: Task
    @State private var isEditMode: Bool
    
    // Form state
    @State private var selectedTags: Set<TaskTag> = []
    @State private var showingLocationPicker = false
    @State private var showingVoiceRecorder = false
    @State private var newSubTaskTitle = ""
    
    // Location state
    @State private var locationSearchText = ""
    @State private var searchResults: [MKMapItem] = []
    
    init(taskManager: TaskManager, task: Task? = nil) {
        self.taskManager = taskManager
        let editTask = task ?? Task(title: "")
        self._task = State(initialValue: editTask)
        self._isEditMode = State(initialValue: task != nil)
        self._selectedTags = State(initialValue: editTask.tags)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                basicInfoSection
                
                // Tags and Priority
                tagsAndPrioritySection
                
                // Due Date and Reminders
                dueDateSection
                
                // Location
                locationSection
                
                // Sub-tasks
                subTasksSection
                
                // Attachments and Voice Notes
                attachmentsSection
                
                // Notes
                notesSection
                
                // Metadata (for edit mode)
                if isEditMode {
                    metadataSection
                }
            }
            .navigationTitle(isEditMode ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(task.title.isEmpty)
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerSheet(
                    task: $task,
                    searchText: $locationSearchText,
                    searchResults: $searchResults
                )
            }
            .sheet(isPresented: $showingVoiceRecorder) {
                VoiceRecorderSheet(task: $task)
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var basicInfoSection: some View {
        Section("Task Details") {
            TextField("Task title", text: $task.title)
                .font(.headline)
        }
    }
    
    private var tagsAndPrioritySection: some View {
        Section("Organization") {
            // Tags picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(TaskTag.allCases) { tag in
                        tagButton(tag)
                    }
                }
            }
            .padding(.vertical, 4)
            
            // Priority picker
            Picker("Priority", selection: $task.priority) {
                ForEach(TaskPriority.allCases) { priority in
                    HStack {
                        Circle()
                            .fill(priority.color)
                            .frame(width: 8, height: 8)
                        Text(priority.rawValue)
                    }
                    .tag(priority)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var dueDateSection: some View {
        Section("Schedule") {
            DatePicker("Due Date", selection: Binding(
                get: { task.dueDate ?? Date() },
                set: { task.dueDate = $0 }
            ), displayedComponents: [.date, .hourAndMinute])
            .disabled(task.dueDate == nil)
            
            Toggle("Set Due Date", isOn: Binding(
                get: { task.dueDate != nil },
                set: { enabled in
                    task.dueDate = enabled ? Date() : nil
                    if !enabled {
                        task.reminderEnabled = false
                        task.reminderDate = nil
                    }
                }
            ))
            
            if task.dueDate != nil {
                Toggle("Reminder", isOn: $task.reminderEnabled)
                
                if task.reminderEnabled {
                    DatePicker("Reminder Time", selection: Binding(
                        get: { task.reminderDate ?? task.dueDate ?? Date() },
                        set: { task.reminderDate = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                }
            }
        }
    }
    
    private var locationSection: some View {
        Section("Location") {
            if let location = task.location {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(location.name ?? "Selected Location")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let address = location.address {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        showingLocationPicker = true
                    }
                    .font(.caption)
                }
                
                Button("Remove Location") {
                    task.location = nil
                }
                .foregroundColor(.red)
            } else {
                Button("Add Location") {
                    showingLocationPicker = true
                }
            }
        }
    }
    
    private var subTasksSection: some View {
        Section("Sub-tasks") {
            // Existing sub-tasks
            ForEach(task.subTasks.indices, id: \.self) { index in
                HStack {
                    Button(action: {
                        task.subTasks[index].isCompleted.toggle()
                    }) {
                        Image(systemName: task.subTasks[index].isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.subTasks[index].isCompleted ? .green : .gray)
                    }
                    
                    TextField("Sub-task", text: $task.subTasks[index].title)
                        .strikethrough(task.subTasks[index].isCompleted)
                        .foregroundColor(task.subTasks[index].isCompleted ? .secondary : .primary)
                }
            }
            .onDelete(perform: deleteSubTasks)
            
            // Add new sub-task
            HStack {
                Image(systemName: "plus.circle")
                    .foregroundColor(.accentColor)
                
                TextField("Add sub-task", text: $newSubTaskTitle)
                    .onSubmit {
                        addSubTask()
                    }
            }
        }
    }
    
    private var attachmentsSection: some View {
        Section("Attachments") {
            // Voice note
            if let voiceNoteURL = task.voiceNoteURL {
                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.blue)
                    
                    Text("Voice Note")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Button("Play") {
                        // TODO: Implement audio playback using voiceNoteURL
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Button("Remove") {
                        task.voiceNoteURL = nil
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            } else {
                Button("Record Voice Note") {
                    showingVoiceRecorder = true
                }
            }
            
            // File attachments
            ForEach(task.attachments) { attachment in
                HStack {
                    Image(systemName: attachment.isImage ? "photo" : "doc")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading) {
                        Text(attachment.fileName)
                            .font(.subheadline)
                        Text(attachment.fileType.uppercased())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            Button("Add Attachment") {
                // TODO: Implement file picker
            }
        }
    }
    
    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $task.notes)
                .frame(minHeight: 100)
        }
    }
    
    private var metadataSection: some View {
        Section("History") {
            HStack {
                Text("Created")
                Spacer()
                Text(task.createdAt, style: .date)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Last Modified")
                Spacer()
                Text(task.updatedAt, style: .relative)
                    .foregroundColor(.secondary)
            }
            
            if let completedAt = task.completedAt {
                HStack {
                    Text("Completed")
                    Spacer()
                    Text(completedAt, style: .relative)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func tagButton(_ tag: TaskTag) -> some View {
        Button(action: {
            if selectedTags.contains(tag) {
                selectedTags.remove(tag)
            } else {
                selectedTags.insert(tag)
            }
            task.tags = selectedTags
        }) {
            Text(tag.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    selectedTags.contains(tag) ? tag.color : tag.color.opacity(0.2)
                )
                .foregroundColor(
                    selectedTags.contains(tag) ? .white : tag.color
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Actions
    
    private func saveTask() {
        if isEditMode {
            taskManager.updateTask(task)
        } else {
            taskManager.addTask(task)
        }
        dismiss()
    }
    
    private func addSubTask() {
        guard !newSubTaskTitle.isEmpty else { return }
        task.addSubTask(newSubTaskTitle)
        newSubTaskTitle = ""
    }
    
    private func deleteSubTasks(offsets: IndexSet) {
        for index in offsets {
            task.removeSubTask(at: index)
        }
    }
}

// MARK: - Reschedule Task Sheet

/// Simple sheet for rescheduling tasks
struct RescheduleTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    let task: Task
    let taskManager: TaskManager
    
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Reschedule Task")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(task.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                DatePicker(
                    "New Due Date",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .padding()
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button("Reschedule") {
                        taskManager.rescheduleTask(task, to: selectedDate)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .padding()
        }
        .onAppear {
            selectedDate = task.dueDate ?? Date()
        }
    }
}

// MARK: - Location Picker Sheet

/// MapKit-based location picker
struct LocationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var task: Task
    @Binding var searchText: String
    @Binding var searchResults: [MKMapItem]
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    TextField("Search locations", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            searchLocations()
                        }
                    
                    Button("Search") {
                        searchLocations()
                    }
                }
                .padding()
                
                // Search results
                if !searchResults.isEmpty {
                    List(searchResults, id: \.self) { item in
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Unknown Location")
                                .font(.headline)
                            
                            if let address = item.placemark.title {
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onTapGesture {
                            selectLocation(item)
                        }
                    }
                    .frame(maxHeight: 200)
                }
                
                // Map view
                Map(position: .constant(MapCameraPosition.region(region)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Use Current") {
                        // TODO: Implement current location
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchLocations() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            searchResults = response.mapItems
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        task.location = TaskLocation(
            coordinate: item.placemark.coordinate,
            address: item.placemark.title,
            name: item.name
        )
        dismiss()
    }
}

// MARK: - Voice Recorder Sheet

/// Voice recording interface
struct VoiceRecorderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var task: Task
    
    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Voice Note")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Recording visualization
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red.opacity(0.3) : Color.gray.opacity(0.3))
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .fill(isRecording ? Color.red : Color.gray)
                        .frame(width: 100, height: 100)
                        .scaleEffect(isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                    
                    Image(systemName: "mic.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                // Recording time
                Text(formatTime(recordingTime))
                    .font(.title)
                    .fontWeight(.medium)
                
                // Controls
                HStack(spacing: 40) {
                    Button(action: {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }) {
                        Text(isRecording ? "Stop" : "Record")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 50)
                            .background(isRecording ? Color.red : Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Voice Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveVoiceNote()
                    }
                    .disabled(recordingTime == 0)
                }
            }
        }
    }
    
    private func startRecording() {
        isRecording = true
        recordingTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingTime += 0.1
        }
        
        // TODO: Start actual audio recording
    }
    
    private func stopRecording() {
        isRecording = false
        timer?.invalidate()
        timer = nil
        
        // TODO: Stop actual audio recording
    }
    
    private func saveVoiceNote() {
        // TODO: Save recorded audio file and set URL
        task.voiceNoteURL = "voice_note_\(Date().timeIntervalSince1970).m4a"
        dismiss()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, milliseconds)
    }
} 