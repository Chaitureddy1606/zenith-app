import SwiftUI

/// Simple working calendar view
struct SimpleCalendarView: View {
    @State private var selectedDate = Date()
    @State private var showingAddEvent = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Calendar Header
                    Text("Calendar")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Current Date
                    Text(selectedDate, style: .date)
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    // Calendar Icon and Description
                    VStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.system(size: 80))
                            .foregroundColor(.accentColor)
                        
                        Text("Your calendar events will appear here")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text("Tap the + button to add your first event")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                    
                    // Sample upcoming events section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Coming Soon:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Full calendar integration")
                            Text("• Event creation and editing")
                            Text("• Reminders and notifications")
                            Text("• Sync with external calendars")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddEvent = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                    .accessibilityLabel("Add Event")
                }
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            AddEventSheet(isPresented: $showingAddEvent)
        }
    }
}

/// Simple add event sheet
struct AddEventSheet: View {
    @Binding var isPresented: Bool
    @State private var eventTitle = ""
    @State private var eventDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $eventTitle)
                    DatePicker("Date & Time", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section {
                    Text("Full event creation functionality will be available in the next update.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // TODO: Implement save functionality
                        isPresented = false
                    }
                    .disabled(eventTitle.isEmpty)
                }
            }
        }
    }
}

#Preview {
    SimpleCalendarView()
} 