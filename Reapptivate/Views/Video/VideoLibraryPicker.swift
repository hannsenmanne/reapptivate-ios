import PhotosUI
import SwiftUI

struct VideoLibraryPicker: UIViewControllerRepresentable {
    let onVideoPicked: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onVideoPicked: onVideoPicked, dismiss: dismiss)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onVideoPicked: (URL) -> Void
        let dismiss: DismissAction

        init(onVideoPicked: @escaping (URL) -> Void, dismiss: DismissAction) {
            self.onVideoPicked = onVideoPicked
            self.dismiss = dismiss
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider,
                  provider.hasItemConformingToTypeIdentifier("public.movie") else {
                dismiss()
                return
            }

            provider.loadFileRepresentation(forTypeIdentifier: "public.movie") { [weak self] url, error in
                guard let self else { return }
                guard let url, error == nil else {
                    Task { @MainActor in self.dismiss() }
                    return
                }
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + ".mov")
                do {
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    Task { @MainActor in
                        self.onVideoPicked(tempURL)
                        self.dismiss()
                    }
                } catch {
                    Task { @MainActor in self.dismiss() }
                }
            }
        }
    }
}
