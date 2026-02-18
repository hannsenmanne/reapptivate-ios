import SwiftUI

/// Inline error banner with contextual recovery actions
struct InlineErrorView: View {
    let message: String
    let errorType: ErrorType
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?

    @State private var hapticTrigger = false

    enum ErrorType {
        case network      // Network connectivity issues
        case server       // Server/API errors
        case validation   // User input validation
        case generic      // General errors

        var icon: String {
            switch self {
            case .network: return "wifi.exclamationmark"
            case .server: return "exclamationmark.triangle.fill"
            case .validation: return "exclamationmark.circle.fill"
            case .generic: return "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .network: return .painAmber
            case .server: return .painRed
            case .validation: return .painAmber
            case .generic: return .painAmber
            }
        }
    }

    /// Creates an error view with retry action (most common pattern)
    init(message: String, errorType: ErrorType = .generic, onRetry: @escaping () -> Void) {
        self.message = message
        self.errorType = errorType
        self.onRetry = onRetry
        self.onDismiss = nil
    }

    /// Creates an error view with dismiss action only
    init(message: String, errorType: ErrorType = .generic, onDismiss: @escaping () -> Void) {
        self.message = message
        self.errorType = errorType
        self.onRetry = nil
        self.onDismiss = onDismiss
    }

    /// Creates an error view with both retry and dismiss actions
    init(message: String, errorType: ErrorType = .generic, onRetry: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.message = message
        self.errorType = errorType
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: errorType.icon)
                .foregroundStyle(errorType.color)
                .font(.appBody)
                .accessibilityHidden(true)

            Text(message)
                .font(.appCaption)
                .foregroundStyle(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if let retry = onRetry {
                Button(action: {
                    hapticTrigger.toggle()
                    retry()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .medium))
                        Text("Erneut")
                            .font(.appCaptionMedium)
                    }
                    .foregroundStyle(.accent)
                }
                .accessibilityLabel("Erneut versuchen")
                .sensoryFeedback(.selection, trigger: hapticTrigger)
            }

            if let dismiss = onDismiss {
                Button(action: {
                    hapticTrigger.toggle()
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.textTertiary)
                }
                .accessibilityLabel("Fehler ausblenden")
                .sensoryFeedback(.selection, trigger: hapticTrigger)
            }
        }
        .padding(12)
        .background(errorType.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(errorTypeLabel): \(message)")
    }

    private var errorTypeLabel: String {
        switch errorType {
        case .network: return "Netzwerkfehler"
        case .server: return "Serverfehler"
        case .validation: return "Eingabefehler"
        case .generic: return "Fehler"
        }
    }
}
