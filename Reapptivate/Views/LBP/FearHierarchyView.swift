import SwiftUI

struct FearHierarchyView: View {
    @Bindable var viewModel: LbpEnhancementsViewModel
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var showExposureLog = false
    @State private var selectedItem: FearHierarchyItem?
    @State private var expandedItemId: String?

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "target")
                    .font(.appTitle3)
                    .foregroundStyle(.farBlue)
                Text(appLanguage == "en" ? "Fear Hierarchy" : "Angst-Hierarchie")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if let hierarchy = viewModel.fearHierarchy {
                let sortedItems = hierarchy.items.sorted { $0.sortOrder < $1.sortOrder }

                ForEach(sortedItems) { item in
                    FearHierarchyItemCard(
                        item: item,
                        isExpanded: expandedItemId == item.id,
                        exposureCount: viewModel.exposureLogs[item.id]?.count ?? 0,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                expandedItemId = expandedItemId == item.id ? nil : item.id
                            }
                        },
                        onLogExposure: {
                            selectedItem = item
                            showExposureLog = true
                        }
                    )
                    .task {
                        await viewModel.loadExposures(itemId: item.id)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 32))
                        .foregroundStyle(.textSecondary)
                    Text(appLanguage == "en" ? "No hierarchy created yet" : "Noch keine Hierarchie erstellt")
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
        .sheet(isPresented: $showExposureLog) {
            if let item = selectedItem {
                ExposureLogSheet(
                    item: item,
                    viewModel: viewModel
                )
                .glassSheet()
            }
        }
    }
}

// MARK: - Fear Hierarchy Item Card

struct FearHierarchyItemCard: View {
    let item: FearHierarchyItem
    let isExpanded: Bool
    let exposureCount: Int
    let onTap: () -> Void
    let onLogExposure: () -> Void

    @AppStorage("appLanguage") private var appLanguage = "de"

    var fearColor: Color {
        if item.fearRating0To10 <= 3 { return .painGreen }
        if item.fearRating0To10 <= 6 { return .painAmber }
        return .painRed
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Rank badge
                    Text("\(item.sortOrder)")
                        .font(.appCaptionBold)
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(fearColor)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.label)
                            .font(.appSubheadlineMedium)
                            .foregroundStyle(.textPrimary)

                        HStack(spacing: 8) {
                            Text(appLanguage == "en" ? "Fear: \(item.fearRating0To10)/10" : "Angst: \(item.fearRating0To10)/10")
                                .font(.appCaption)
                                .foregroundStyle(fearColor)

                            if exposureCount > 0 {
                                Text(appLanguage == "en" ? "\(exposureCount) exp." : "\(exposureCount) Exp.")
                                    .font(.appCaption)
                                    .foregroundStyle(.textSecondary)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                Divider()
                    .padding(.horizontal, 12)

                VStack(spacing: 12) {
                    // Fear rating bar
                    FearRatingBar(rating: item.fearRating0To10)

                    // Log exposure button
                    Button(action: onLogExposure) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text(appLanguage == "en" ? "Log exposure" : "Exposition protokollieren")
                        }
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.farBlue)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                    }
                }
                .padding(12)
            }
        }
        .cardStyle(padding: 0)
    }
}

// MARK: - Fear Rating Bar

struct FearRatingBar: View {
    let rating: Int
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(appLanguage == "en" ? "Fear Level" : "Angst-Level")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                Spacer()
                Text("\(rating)/10")
                    .font(.appCaptionBold)
                    .foregroundStyle(.textPrimary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.textSecondary.opacity(0.15))
                        .frame(height: 8)

                    Rectangle()
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(rating) / 10, height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    var barColor: Color {
        if rating <= 3 { return .painGreen }
        if rating <= 6 { return .painAmber }
        return .painRed
    }
}
