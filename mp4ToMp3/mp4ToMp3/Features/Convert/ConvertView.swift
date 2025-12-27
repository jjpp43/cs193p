import SwiftUI
import PhotosUI
import UniformTypeIdentifiers


/// Lets PhotosPicker hand us a real local file URL (copied into a temp location)
struct PickedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            // Exporting (not needed here)
            SentTransferredFile(movie.url)
        } importing: { received in
            // Copy the picked movie into a temp file we can use with AVFoundation
            let tempDir = FileManager.default.temporaryDirectory
            let tempURL = tempDir.appendingPathComponent(received.file.lastPathComponent)

            // Overwrite if already exists
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            try FileManager.default.copyItem(at: received.file, to: tempURL)

            return PickedMovie(url: tempURL)
        }
    }
}

struct ConvertView: View {
    @StateObject private var vm = ConvertViewModel()

    @State private var showPicker = false
    @State private var showShare = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {

                        header

                        CardSection("1. Input", subtitle: "Select an MP4/MOV video.") {
                            VStack(alignment: .leading, spacing: 12) {
                                inputRow

                                HStack(spacing: 12) {
                                    // Files button
                                    Button {
                                        showPicker = true
                                    } label: {
                                        Label("Files", systemImage: "doc.badge.plus")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.accentColor)

                                    // Photos button
                                    PhotosPicker(
                                        selection: $selectedPhotoItem,
                                        matching: .videos,
                                        photoLibrary: .shared()
                                    ) {
                                        Label("Photos", systemImage: "photo.on.rectangle")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.accentColor)
                                }
                            }
                        }

                        CardSection("2. Convert", subtitle: "Extract audio and export as M4A (reliable on iOS).") {
                            VStack(alignment: .leading, spacing: 12) {
                                Button {
                                    Task { await vm.convert() }
                                } label: {
                                    Label(vm.isConverting ? "Converting…" : "Convert to Audio", systemImage: "waveform")
                                }
                                .buttonStyle(PrimaryButtonStyle(isDisabled: vm.selectedVideoURL == nil || vm.isConverting))
                                .disabled(vm.selectedVideoURL == nil || vm.isConverting)

                                VStack(alignment: .leading, spacing: 8) {
                                    ProgressView(value: vm.progress)
                                        .tint(.accentColor)

                                    HStack {
                                        Text(vm.statusText)
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(Int(vm.progress * 100))%")
                                            .font(.footnote.monospacedDigit())
                                            .foregroundColor(.secondary)
                                    }

                                    if let error = vm.errorMessage {
                                        Label(error, systemImage: "exclamationmark.triangle.fill")
                                            .font(.footnote)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }

                        CardSection("3. Output", subtitle: "Share the converted file or save it to Files.") {
                            if let converted = vm.lastConverted {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "music.note")
                                            .font(.title2)
                                            .foregroundColor(.accentColor)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(converted.outputAudioURL.lastPathComponent)
                                                .font(.headline)
                                            Text(converted.outputAudioURL.deletingLastPathComponent().lastPathComponent)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()
                                    }

                                    Button {
                                        showShare = true
                                    } label: {
                                        Label("Share / Save to Files", systemImage: "square.and.arrow.up")
                                    }
                                    .buttonStyle(.bordered)
                                }
                            } else {
                                emptyState
                            }
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Video → Audio")
                        .font(.headline)
                }
            }
        }
        // Handle Photos selection: convert PhotosPickerItem -> local file URL
        .onChange(of: selectedPhotoItem) { newItem in
            guard let newItem else { return }

            Task {
                do {
                    if let picked = try await newItem.loadTransferable(type: PickedMovie.self) {
                        vm.setSelectedVideo(url: picked.url)
                    } else {
                        print("PhotosPicker: loadTransferable returned nil")
                    }
                } catch {
                    print("PhotosPicker failed:", error)
                }

                // Optional: allow picking the same video again
                selectedPhotoItem = nil
            }
        }
        // Files picker sheet
        .sheet(isPresented: $showPicker) {
            VideoPicker { url in
                vm.setSelectedVideo(url: url)
                showPicker = false
            }
        }
        // Share sheet
        .sheet(isPresented: $showShare) {
            if let converted = vm.lastConverted {
                ShareSheet(items: [converted.outputAudioURL])
            }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pick a video file and extract its audio. No uploads.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }

    private var inputRow: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                Image(systemName: "film")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(vm.selectedVideoURL?.lastPathComponent ?? "No video selected")
                    .font(.headline)
                    .lineLimit(1)

                Text(vm.selectedVideoURL?.path ?? "Choose a file from Files (mp4/mov) or Photos.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No output yet", systemImage: "sparkles")
                .font(.headline)
            Text("After converting, your audio file will appear here with a share button.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}
