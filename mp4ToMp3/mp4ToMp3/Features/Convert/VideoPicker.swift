import SwiftUI
import UniformTypeIdentifiers
import UIKit

/// Wraps UIDocumentPickerViewController so we can pick an MP4/MOV from Files.
struct VideoPicker: UIViewControllerRepresentable {

    /// Called when the user selects a file.
    var onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Allow video file types. MP4 and QuickTime are common.
        let types: [UTType] = [
            .mpeg4Movie,
            .quickTimeMovie,
            .movie
        ]

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let first = urls.first else { return }
            onPick(first)
        }
    }
}
