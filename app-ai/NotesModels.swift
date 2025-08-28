import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Core Models

/// Simple Note model
struct Note: Identifiable, Codable, Hashable {
    var id: UUID { _id }
    private let _id = UUID()
    var title: String
    var content: String
    var createdDate: Date
    var modifiedDate: Date
    var isPinned: Bool = false
    var folderId: UUID?
    var tags: [String] = []
    var attachments: [NoteAttachment] = []
    
    init(title: String = "", content: String = "") {
        self.title = title
        self.content = content
        self.createdDate = Date()
        self.modifiedDate = Date()
    }
}

/// Note attachment model
struct NoteAttachment: Identifiable, Codable, Hashable {
    var id: UUID { _id }
    private let _id = UUID()
    var type: AttachmentType
    var data: Data
    var fileName: String
    var createdDate: Date
    
    init(type: AttachmentType, data: Data, fileName: String) {
        self.type = type
        self.data = data
        self.fileName = fileName
        self.createdDate = Date()
    }
}

/// Attachment types
enum AttachmentType: String, CaseIterable, Codable {
    case image = "image"
    case audio = "audio"
    case drawing = "drawing"
    case document = "document"
    
    var icon: String {
        switch self {
        case .image: return "photo"
        case .audio: return "waveform"
        case .drawing: return "pencil.and.outline"
        case .document: return "doc.text"
        }
    }
}

/// Note folder model
struct NoteFolder: Identifiable, Codable, Hashable {
    var id: UUID { _id }
    private let _id = UUID()
    var name: String
    var icon: String
    var color: Color
    var notes: [UUID] = []
    
    init(name: String, icon: String = "folder", color: Color = .blue) {
        self.name = name
        self.icon = icon
        self.color = color
    }
}

// MARK: - Extensions

extension Color: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hex = try container.decode(String.self)
        self.init(hex: hex)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(toHex())
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let hex = String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        return hex
    }
} 