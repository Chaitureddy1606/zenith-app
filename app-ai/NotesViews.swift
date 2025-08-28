import SwiftUI

// MARK: - Main Notes View

/// Simple Notes view with list and detail
struct NotesView: View {
    @StateObject private var notesManager = NotesManager()
    @State private var showingAddNote = false
    @State private var showingAddFolder = false
    
    var body: some View {
        NavigationSplitView {
            // MARK: - Sidebar
            sidebar
        } detail: {
            // MARK: - Detail View
            detailView
        }
        .navigationTitle("Notes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddNote = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddNote) {
            AddNoteView(notesManager: notesManager)
        }
        .sheet(isPresented: $showingAddFolder) {
            AddFolderView(notesManager: notesManager)
        }
    }
    
    // MARK: - Sidebar
    private var sidebar: some View {
        List(selection: $notesManager.selectedFolder) {
            ForEach(notesManager.folders) { folder in
                NavigationLink(value: folder) {
                    HStack {
                        Image(systemName: folder.icon)
                            .foregroundColor(folder.color)
                        Text(folder.name)
                        Spacer()
                        Text("\(notesManager.notesForFolder(folder).count)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("Folders")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddFolder = true }) {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
    }
    
    // MARK: - Detail View
    private var detailView: some View {
        Group {
            if let selectedFolder = notesManager.selectedFolder {
                notesList(for: selectedFolder)
            } else {
                ContentUnavailableView("Select a Folder", systemImage: "folder")
            }
        }
    }
    
    // MARK: - Notes List
    private func notesList(for folder: NoteFolder) -> some View {
        List {
            ForEach(notesManager.filteredNotes) { note in
                NavigationLink(value: note) {
                    NoteRowView(note: note)
                }
            }
            .onDelete(perform: deleteNotes)
        }
        .navigationTitle(selectedFolder?.name ?? "Notes")
        .searchable(text: $notesManager.searchText, prompt: "Search notes")
        .sheet(item: $notesManager.selectedNote) { note in
            NoteDetailView(note: note, notesManager: notesManager)
        }
    }
    
    // MARK: - Helper Methods
    private func deleteNotes(offsets: IndexSet) {
        let notesToDelete = offsets.map { notesManager.filteredNotes[$0] }
        for note in notesToDelete {
            notesManager.deleteNote(note)
        }
    }
    
    private var selectedFolder: NoteFolder? {
        notesManager.selectedFolder
    }
}

// MARK: - Note Row View

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(note.title.isEmpty ? "Untitled Note" : note.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Text(note.modifiedDate, style: .relative)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                
                Spacer()
                
                if !note.tags.isEmpty {
                    Text(note.tags.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Note View

struct AddNoteView: View {
    @ObservedObject var notesManager: NotesManager
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Title", text: $title)
                    .font(.title2)
                    .padding()
                
                TextEditor(text: $content)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        notesManager.addNote(title: title, content: content)
                        dismiss()
                    }
                    .disabled(title.isEmpty && content.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Folder View

struct AddFolderView: View {
    @ObservedObject var notesManager: NotesManager
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedIcon = "folder"
    @State private var selectedColor = Color.blue
    
    private let icons = ["folder", "tray", "pin", "star", "heart", "bookmark", "tag", "flag"]
    private let colors: [Color] = [.blue, .green, .orange, .red, .purple, .pink, .yellow, .gray]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Folder Details") {
                    TextField("Folder Name", text: $name)
                    
                    HStack {
                        Text("Icon")
                        Spacer()
                        ForEach(icons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .foregroundColor(selectedIcon == icon ? selectedColor : .primary)
                                    .font(.title2)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        ForEach(colors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        notesManager.addFolder(name: name, icon: selectedIcon, color: selectedColor)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Note Detail View

struct NoteDetailView: View {
    let note: Note
    @ObservedObject var notesManager: NotesManager
    @Environment(\.dismiss) private var dismiss
    @State private var editedTitle: String
    @State private var editedContent: String
    
    init(note: Note, notesManager: NotesManager) {
        self.note = note
        self.notesManager = notesManager
        self._editedTitle = State(initialValue: note.title)
        self._editedContent = State(initialValue: note.content)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Title", text: $editedTitle)
                    .font(.title2)
                    .padding()
                
                TextEditor(text: $editedContent)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedNote = note
                        updatedNote.title = editedTitle
                        updatedNote.content = editedContent
                        notesManager.updateNote(updatedNote)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NotesView()
} 