import SwiftUI
@preconcurrency import AVFoundation

struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "de"
    let onCodeScanned: (String) -> Void

    @State private var cameraPermissionGranted = false
    @State private var showPermissionDenied = false

    var body: some View {
        let isEn = appLanguage == "en"
        NavigationStack {
            ZStack {
                if cameraPermissionGranted {
                    QRCameraPreview(onCodeScanned: { code in
                        onCodeScanned(code)
                        dismiss()
                    })
                    .ignoresSafeArea()

                    // Overlay with scanning guide
                    VStack {
                        Spacer()

                        RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous)
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 250, height: 250)

                        Text(isEn ? "Hold QR code in the frame" : "QR-Code in den Rahmen halten")
                            .font(.appSubheadlineMedium)
                            .foregroundStyle(.white)
                            .padding(.top, 16)

                        Spacer()
                    }
                } else if showPermissionDenied {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.textSecondary)

                        Text(isEn ? "Camera access required" : "Kamerazugriff erforderlich")
                            .font(.appTitle3)

                        Text(isEn ? "Please allow camera access in Settings to scan QR codes." : "Bitte erlauben Sie den Kamerazugriff in den Einstellungen, um QR-Codes zu scannen.")
                            .font(.appBody)
                            .foregroundStyle(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button(isEn ? "Open Settings" : "Einstellungen öffnen") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.accentFilled)
                        .padding(.horizontal, 24)
                    }
                } else {
                    ProgressView(isEn ? "Loading camera..." : "Kamera wird geladen...")
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEn ? "Cancel" : "Abbrechen") { dismiss() }
                }
            }
            .navigationTitle(isEn ? "Scan QR code" : "QR-Code scannen")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await checkCameraPermission()
        }
    }

    private func checkCameraPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraPermissionGranted = granted
            showPermissionDenied = !granted
        default:
            showPermissionDenied = true
        }
    }
}

// MARK: - Camera Preview (UIKit bridge)

struct QRCameraPreview: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerController {
        let controller = QRScannerController()
        controller.onCodeScanned = onCodeScanned
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerController, context: Context) {}
}

class QRScannerController: UIViewController {
    var onCodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false
    private let delegateHandler = QRDelegateHandler()

    override func viewDidLoad() {
        super.viewDidLoad()

        let session = AVCaptureSession()
        captureSession = session

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            delegateHandler.onDetected = { [weak self] value in
                guard let self, !self.hasScanned else { return }
                self.hasScanned = true
                self.captureSession?.stopRunning()
                self.onCodeScanned?(value)
            }
            output.setMetadataObjectsDelegate(delegateHandler, queue: .main)
            output.metadataObjectTypes = [.qr]
        }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.frame = view.layer.bounds
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
}

// Separate delegate to avoid main-actor isolation conflict
private class QRDelegateHandler: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var onDetected: ((String) -> Void)?

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }
        onDetected?(value)
    }
}
