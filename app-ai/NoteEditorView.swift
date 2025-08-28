import SwiftUI

// MARK: - Note Editor View

/// Simple note editor view
struct NoteEditorView: View {
    let note: Note
    @ObservedObject var notesManager: NotesManager
    @Environment(\.dismiss) private var dismiss
    @State private var editedTitle: String
    @State private var editedContent: String
    @State private var isEditing = false
    
    init(note: Note, notesManager: NotesManager) {
        self.note = note
        self.notesManager = notesManager
        self._editedTitle = State(initialValue: note.title)
        self._editedContent = State(initialValue: note.content)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isEditing {
                    editingView
                } else {
                    readingView
                }
            }
            .navigationTitle(isEditing ? "Edit Note" : "Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            cancelEditing()
                        }
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveNote()
                        }
                        .disabled(editedTitle.isEmpty && editedContent.isEmpty)
                    } else {
                        Button("Edit") {
                            startEditing()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Reading View
    private var readingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !note.title.isEmpty {
                    Text(note.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                }
                
                if !note.content.isEmpty {
                    Text(note.content)
                        .font(.body)
                        .padding(.horizontal)
                }
                
                if note.title.isEmpty && note.content.isEmpty {
                    ContentUnavailableView("Empty Note", systemImage: "doc.text")
                        .padding()
                }
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Created \(note.createdDate, style: .date)", systemImage: "calendar")
                        Spacer()
                        if note.isPinned {
                            Label("Pinned", systemImage: "pin.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack {
                        Label("Modified \(note.modifiedDate, style: .relative)", systemImage: "clock")
                        Spacer()
                        if let folderId = note.folderId,
                           let folder = notesManager.folders.first(where: { $0.id == folderId }) {
                            Label(folder.name, systemImage: folder.icon)
                                .foregroundColor(folder.color)
                        }
                    }
                    
                    if !note.tags.isEmpty {
                        HStack {
                            Label("Tags", systemImage: "tag")
                            Spacer()
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 4) {
                                    ForEach(note.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.accentColor.opacity(0.1))
                                            .foregroundColor(.accentColor)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                
                Spacer(minLength: 100)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Editing View
    private var editingView: some View {
        VStack(spacing: 16) {
            TextField("Title", text: $editedTitle)
                .font(.title2)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            TextEditor(text: $editedContent)
                .font(.body)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
    }
    
    // MARK: - Actions
    private func startEditing() {
        editedTitle = note.title
        editedContent = note.content
        isEditing = true
    }
    
    private func cancelEditing() {
        editedTitle = note.title
        editedContent = note.content
        isEditing = false
    }
    
    private func saveNote() {
        var updatedNote = note
        updatedNote.title = editedTitle
        updatedNote.content = editedContent
        notesManager.updateNote(updatedNote)
        isEditing = false
    }
}

// MARK: - Preview

#Preview {
    NoteEditorView(
        note: Note(title: "Sample Note", content: "This is a sample note content."),
        notesManager: NotesManager()
    )
} 