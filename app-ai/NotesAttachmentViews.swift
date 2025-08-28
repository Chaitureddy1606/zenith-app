import SwiftUI
import AVFoundation
import PhotosUI

// MARK: - Attachment Views

/// View for displaying note attachments
struct AttachmentView: View {
    let attachment: NoteAttachment
    @State private var showingFullScreen = false
    
    var body: some View {
        VStack {
            switch attachment.type {
            case .image:
                if let image = UIImage(data: attachment.data) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            showingFullScreen = true
                        }
                } else {
                    ContentUnavailableView("Image Unavailable", systemImage: "photo")
                }
                
            case .audio:
                AudioPlayerView(audioData: attachment.data)
                
            case .drawing:
                if let image = UIImage(data: attachment.data) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            showingFullScreen = true
                        }
                } else {
                    ContentUnavailableView("Drawing Unavailable", systemImage: "pencil.and.outline")
                }
                
            case .document:
                DocumentView(fileName: attachment.fileName)
            }
        }
        .sheet(isPresented: $showingFullScreen) {
            FullScreenAttachmentView(attachment: attachment)
        }
    }
}

// MARK: - Audio Player View

struct AudioPlayerView: View {
    let audioData: Data
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Audio Recording")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text(formatTime(currentTime))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(formatTime(duration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $currentTime, in: 0...max(duration, 1)) { editing in
                if !editing {
                    seekToTime(currentTime)
                }
            }
            .disabled(audioPlayer == nil)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func setupAudioPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            let delegate = AudioPlayerDelegate()
            audioPlayer?.delegate = delegate
            duration = audioPlayer?.duration ?? 0
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if let player = audioPlayer, player.isPlaying {
                    currentTime = player.currentTime
                }
            }
        } catch {
            print("Failed to setup audio player: \(error)")
        }
    }
    
    private func togglePlayback() {
        guard let player = audioPlayer else { return }
        
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    private func seekToTime(_ time: TimeInterval) {
        audioPlayer?.currentTime = time
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func cleanup() {
        audioPlayer?.stop()
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Document View

struct DocumentView: View {
    let fileName: String
    
    var body: some View {
        HStack {
            Image(systemName: "doc.text")
                .font(.title2)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(fileName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("Document")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Open") {
                // Handle document opening
            }
            .font(.caption)
            .foregroundColor(.accentColor)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Full Screen Attachment View

struct FullScreenAttachmentView: View {
    let attachment: NoteAttachment
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                switch attachment.type {
                case .image, .drawing:
                    if let image = UIImage(data: attachment.data) {
                        ScrollView([.horizontal, .vertical]) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    } else {
                        ContentUnavailableView("Image Unavailable", systemImage: "photo")
                    }
                    
                case .audio:
                    AudioPlayerView(audioData: attachment.data)
                        .padding()
                    
                case .document:
                    DocumentView(fileName: attachment.fileName)
                        .padding()
                }
            }
            .navigationTitle(attachment.fileName)
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
}

// MARK: - Audio Player Delegate

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Handle playback completion if needed
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AttachmentView(
            attachment: NoteAttachment(
                type: .image,
                data: Data(),
                fileName: "sample.jpg"
            )
        )
        
        AudioPlayerView(audioData: Data())
        
        DocumentView(fileName: "document.pdf")
    }
    .padding()
} 