import SwiftUI

struct LoadingView: View {
    var message: String?

    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        let isEn = appLanguage == "en"

        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(message ?? (isEn ? "Loading..." : "Laden..."))
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBg)
    }
}

#Preview {
    LoadingView()
}
