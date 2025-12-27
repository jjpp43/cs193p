import Foundation

/// Represents one exported audio file created by the app.
struct ConvertedFile: Identifiable, Equatable {
    let id = UUID()
    let sourceVideoURL: URL
    let outputAudioURL: URL
    let createdAt: Date
}
