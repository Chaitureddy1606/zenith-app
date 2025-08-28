import Foundation
import SwiftUI
import Combine

// MARK: - Notes Manager

/// Simple manager class for notes functionality
class NotesManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var notes: [Note] = []
    @Published var folders: [NoteFolder] = []
    @Published var selectedNote: Note?
    @Published var selectedFolder: NoteFolder?
    @Published var searchText: String = ""
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let notesKey = "savedNotes"
    private let foldersKey = "savedFolders"
    
    // MARK: - Initialization
    init() {
        loadData()
        setupAutoSave()
    }
    
    // MARK: - Data Management
    
    /// Load saved data from UserDefaults
    private func loadData() {
        if let notesData = userDefaults.data(forKey: notesKey),
           let savedNotes = try? JSONDecoder().decode([Note].self, from: notesData) {
            notes = savedNotes
        }
        
        if let foldersData = userDefaults.data(forKey: foldersKey),
           let savedFolders = try? JSONDecoder().decode([NoteFolder].self, from: foldersData) {
            folders = savedFolders
        }
        
        // Create default folders if none exist
        if folders.isEmpty {
            createDefaultFolders()
        }
    }
    
    /// Save data to UserDefaults
    private func saveData() {
        if let notesData = try? JSONEncoder().encode(notes) {
            userDefaults.set(notesData, forKey: notesKey)
        }
        
        if let foldersData = try? JSONEncoder().encode(folders) {
            userDefaults.set(foldersData, forKey: foldersKey)
        }
    }
    
    /// Create default folders
    private func createDefaultFolders() {
        let allNotes = NoteFolder(name: "All Notes", icon: "tray", color: .blue)
        let pinned = NoteFolder(name: "Pinned", icon: "pin", color: .orange)
        let recentlyDeleted = NoteFolder(name: "Recently Deleted", icon: "trash", color: .red)
        
        folders = [allNotes, pinned, recentlyDeleted]
    }
    
    // MARK: - Auto-save Setup
    
    /// Setup auto-save functionality using Combine debounce
    private func setupAutoSave() {
        $notes
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Note Operations
    
    /// Add a new note
    func addNote(title: String = "", content: String = "") {
        let newNote = Note(title: title, content: content)
        notes.append(newNote)
        selectedNote = newNote
    }
    
    /// Update an existing note
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.modifiedDate = Date()
            notes[index] = updatedNote
            selectedNote = updatedNote
        }
    }
    
    /// Delete a note
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        if selectedNote?.id == note.id {
            selectedNote = nil
        }
    }
    
    /// Pin/unpin a note
    func togglePin(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isPinned.toggle()
        }
    }
    
    /// Move note to folder
    func moveNote(_ note: Note, to folderId: UUID?) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].folderId = folderId
        }
    }
    
    // MARK: - Folder Operations
    
    /// Add a new folder
    func addFolder(name: String, icon: String = "folder", color: Color = .blue) {
        let newFolder = NoteFolder(name: name, icon: icon, color: color)
        folders.append(newFolder)
    }
    
    /// Delete a folder
    func deleteFolder(_ folder: NoteFolder) {
        folders.removeAll { $0.id == folder.id }
        // Move notes from deleted folder to "All Notes"
        for index in notes.indices {
            if notes[index].folderId == folder.id {
                notes[index].folderId = nil
            }
        }
    }
    
    // MARK: - Search and Filtering
    
    /// Get filtered notes based on search text and selected folder
    var filteredNotes: [Note] {
        var filtered = notes
        
        // Filter by folder
        if let selectedFolder = selectedFolder {
            if selectedFolder.name == "All Notes" {
                // Show all notes
            } else if selectedFolder.name == "Pinned" {
                filtered = filtered.filter { $0.isPinned }
            } else if selectedFolder.name == "Recently Deleted" {
                // Show recently deleted notes (implement if needed)
                filtered = []
            } else {
                filtered = filtered.filter { $0.folderId == selectedFolder.id }
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by pinned status and modification date
        return filtered.sorted { note1, note2 in
            if note1.isPinned != note2.isPinned {
                return note1.isPinned
            }
            return note1.modifiedDate > note2.modifiedDate
        }
    }
    
    /// Get notes for a specific folder
    func notesForFolder(_ folder: NoteFolder) -> [Note] {
        if folder.name == "All Notes" {
            return notes
        } else if folder.name == "Pinned" {
            return notes.filter { $0.isPinned }
        } else {
            return notes.filter { $0.folderId == folder.id }
        }
    }
} 