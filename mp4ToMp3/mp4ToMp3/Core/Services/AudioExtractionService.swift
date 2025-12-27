import Foundation
import AVFoundation

/// Handles extracting audio from a local video file.
/// This exports audio to M4A (AAC) because it's reliable with AVFoundation.
///
/// If you later add MP3 support, this is the file you'd change.
final class AudioExtractionService {

    /// Extracts audio from `videoURL` and writes to `outputURL`.
    /// - Parameters:
    ///   - videoURL: Local file URL (usually security-scoped from Files app)
    ///   - outputURL: Destination file URL in your sandbox
    ///   - onProgress: Called with 0.0...1.0 while exporting
    func extractAudioToM4A(
        videoURL: URL,
        outputURL: URL,
        onProgress: @escaping (Double) -> Void
    ) async throws {

        // AVAsset represents the media at the URL.
        let asset = AVAsset(url: videoURL)

        // Choose a preset. "AppleM4A" exports audio-only as .m4a (AAC).
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw ConvertError.exportSessionCreationFailed
        }

        // Ensure we don't have an old file at the same path.
        try FileService.removeIfExists(outputURL)

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.shouldOptimizeForNetworkUse = true // optional (fine either way)

        // Progress polling: AVAssetExportSession doesn't provide async progress updates by default.
        // We'll poll `exportSession.progress` while the export runs.
        let progressTask = Task {
            while exportSession.status == .exporting {
                onProgress(Double(exportSession.progress))
                try? await Task.sleep(nanoseconds: 150_000_000) // 0.15s
            }
        }

        // Perform export with async/await.
        // On iOS 15+, you can use exportSession.export() async in some contexts,
        // but to keep this compatible, we'll bridge with a continuation.
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            exportSession.exportAsynchronously {
                // Stop progress polling once export finishes.
                progressTask.cancel()

                switch exportSession.status {
                case .completed:
                    onProgress(1.0)
                    continuation.resume()
                case .failed:
                    let msg = exportSession.error?.localizedDescription ?? "Unknown error"
                    continuation.resume(throwing: ConvertError.exportFailed(msg))
                case .cancelled:
                    let msg = exportSession.error?.localizedDescription ?? "Cancelled"
                    continuation.resume(throwing: ConvertError.exportFailed(msg))
                default:
                    continuation.resume(throwing: ConvertError.unknown)
                }
            }
        }
    }
}
