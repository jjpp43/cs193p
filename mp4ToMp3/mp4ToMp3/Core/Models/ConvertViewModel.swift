import Foundation

@MainActor
final class ConvertViewModel: ObservableObject {

    // UI state
    @Published var selectedVideoURL: URL?
    @Published var isConverting: Bool = false
    @Published var progress: Double = 0
    @Published var statusText: String = "Pick a video to begin."
    @Published var lastConverted: ConvertedFile?
    @Published var errorMessage: String?

    private let extractor = AudioExtractionService()

    /// Call this when the user picks a file from the document picker.
    func setSelectedVideo(url: URL) {
        selectedVideoURL = url
        lastConverted = nil
        progress = 0
        errorMessage = nil
        statusText = "Ready to convert: \(url.lastPathComponent)"
    }

    /// Start conversion.
    func convert() async {
        guard let videoURL = selectedVideoURL else {
            errorMessage = "No video selected."
            return
        }

        isConverting = true
        progress = 0
        errorMessage = nil
        statusText = "Converting…"

        // IMPORTANT:
        // Files app URLs are often "security-scoped".
        // You must start access, then stop access when finished.
        let canAccess = videoURL.startAccessingSecurityScopedResource()
        guard canAccess else {
            isConverting = false
            throwError(ConvertError.cannotAccessSecurityScopedResource)
            return
        }

        defer {
            // Always stop accessing when done.
            videoURL.stopAccessingSecurityScopedResource()
        }

        do {
            // Make an output path in our sandbox.
            let outputURL = try FileService.makeOutputURL(for: videoURL, ext: "m4a")

            // Run the export.
            try await extractor.extractAudioToM4A(
                videoURL: videoURL,
                outputURL: outputURL,
                onProgress: { [weak self] p in
                    // This closure can run off-main; hop to main safely.
                    Task { @MainActor in
                        self?.progress = p
                    }
                }
            )

            lastConverted = ConvertedFile(
                sourceVideoURL: videoURL,
                outputAudioURL: outputURL,
                createdAt: Date()
            )
            statusText = "Done! Created: \(outputURL.lastPathComponent)"
        } catch {
            throwError(error)
        }

        isConverting = false
    }

    private func throwError(_ error: Error) {
        errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        statusText = "Failed."
    }
}
