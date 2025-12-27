import Foundation
import PhotosUI

enum FileService {

    /// Returns the app's Documents directory (sandboxed).
    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    /// A dedicated folder for converted audio files.
    static func outputDirectory() throws -> URL {
        let dir = documentsDirectory().appendingPathComponent("ConvertedAudio", isDirectory: true)

        // Create the folder if it doesn't exist yet.
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Builds a safe output filename.
    /// Example: input `MyVideo.mp4` -> output `MyVideo-audio.m4a`
    static func makeOutputURL(for videoURL: URL, ext: String = "m4a") throws -> URL {
        let baseName = videoURL.deletingPathExtension().lastPathComponent
        let filename = "\(baseName)-audio.\(ext)"
        return try outputDirectory().appendingPathComponent(filename)
    }

    /// Removes a file if it already exists (useful for overwriting).
    static func removeIfExists(_ url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
