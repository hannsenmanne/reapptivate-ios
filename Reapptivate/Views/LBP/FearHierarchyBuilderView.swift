import SwiftUI

struct FearHierarchyBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: LbpEnhancementsViewModel

    @State private var items: [BuilderItem] = []
    @State private var isSaving = false
    @State private var showSuggestions = true

    private let suggestions = [
        "Schweres Heben",
        "Langes Sitzen",
        "Sport treiben",
        "Bucken",
        "Treppensteigen",
        "Gartenarbeit",
        "Einkaufen tragen",
        "Laufen/Joggen"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Erstellen Sie eine Liste von Aktivitäten, vor denen Sie Angst haben oder die Sie vermeiden.")
                            .font(.appSubheadline)
                            .foregroundStyle(.textSecondary)
                        Text("Bewerten Sie jede Aktivität mit einem Angst-Level von 0 (keine Angst) bis 10 (maximale Angst).")
                            .font(.appSubheadline)
                            .foregroundStyle(.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .infoBoxStyle(color: .farBlue)

                    // Suggested activities
                    if showSuggestions && items.count < 3 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vorschläge")
                                .font(.appCaptionMedium)
                                .foregroundStyle(.textSecondary)

                            FlowLayoutSuggestions(items: unusedSuggestions) { suggestion in
                                addItem(name: suggestion)
                            }
                        }
                    }

                    // Items
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        BuilderItemCard(
                            item: $items[index],
                            rank: index + 1,
                            onMoveUp: index > 0 ? { moveItem(from: index, to: index - 1) } : nil,
                            onMoveDown: index < items.count - 1 ? { moveItem(from: index, to: index + 1) } : nil,
                            onDelete: { items.remove(at: index) }
                        )
                    }

                    // Add button
                    Button {
                        addItem(name: "")
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                            Text("Aktivität hinzufügen")
                        }
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.farBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.farBlue.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous)
                                .strokeBorder(Color.farBlue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
                        }
                    }

                    // Save button
                    if !items.isEmpty {
                        Button {
                            Task { await save() }
                        } label: {
                            Group {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Hierarchie speichern")
                                }
                            }
                            .font(.appBodySemibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(canSave ? Color.farBlue : Color.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                        }
                        .disabled(!canSave || isSaving)
                    }
                }
                .padding(24)
            }
            .background(Color.appBg)
            .navigationTitle("Angst-Hierarchie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }

    // MARK: - Helpers

    private var canSave: Bool {
        items.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            && !items.isEmpty
    }

    private var unusedSuggestions: [String] {
        suggestions.filter { suggestion in
            !items.contains { $0.name == suggestion }
        }
    }

    private func addItem(name: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            items.append(BuilderItem(name: name, fearRating: 5))
        }
    }

    private func moveItem(from: Int, to: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    private func save() async {
        isSaving = true
        let inputItems = items.enumerated().map { index, item in
            FearHierarchyItemInput(
                label: item.name.trimmingCharacters(in: .whitespaces),
                context: nil,
                fearRating: item.fearRating,
                sortOrder: index,
                steps: nil
            )
        }
        if await viewModel.saveFearHierarchy(items: inputItems) {
            dismiss()
        }
        isSaving = false
    }
}

// MARK: - Builder Item Model

struct BuilderItem: Identifiable {
    let id = UUID()
    var name: String
    var fearRating: Int
}

// MARK: - Builder Item Card

struct BuilderItemCard: View {
    @Binding var item: BuilderItem
    let rank: Int
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                // Reorder buttons
                VStack(spacing: 4) {
                    Button { onMoveUp?() } label: {
                        Image(systemName: "chevron.up")
                            .font(.appCaption2)
                            .foregroundStyle(onMoveUp != nil ? .textSecondary : .clear)
                    }
                    .disabled(onMoveUp == nil)

                    Text("\(rank)")
                        .font(.appCaptionBold)
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(ratingColor)
                        .clipShape(Circle())

                    Button { onMoveDown?() } label: {
                        Image(systemName: "chevron.down")
                            .font(.appCaption2)
                            .foregroundStyle(onMoveDown != nil ? .textSecondary : .clear)
                    }
                    .disabled(onMoveDown == nil)
                }

                VStack(spacing: 8) {
                    // Activity name
                    TextField("Aktivität", text: $item.name)
                        .font(.appSubheadline)
                        .padding(10)
                        .background(Color.appBg)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous))

                    // Fear rating slider
                    HStack(spacing: 8) {
                        Text("Angst:")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)

                        Slider(value: Binding(
                            get: { Double(item.fearRating) },
                            set: { item.fearRating = Int($0) }
                        ), in: 0...10, step: 1)
                        .tint(ratingColor)

                        Text("\(item.fearRating)")
                            .font(.appSubheadlineSemibold.monospacedDigit())
                            .foregroundStyle(ratingColor)
                            .frame(width: 24)
                    }
                }

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.appCaption)
                        .foregroundStyle(.painRed)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .padding(12)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.cardRadius, style: .continuous).stroke(Color.gray200, lineWidth: 1))
    }

    var ratingColor: Color {
        if item.fearRating <= 3 { return .painGreen }
        if item.fearRating <= 6 { return .painAmber }
        return .painRed
    }
}

// MARK: - Flow Layout for Suggestions

struct FlowLayoutSuggestions: View {
    let items: [String]
    let onTap: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 100), spacing: 8)
        ], spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button {
                    onTap(item)
                } label: {
                    Text(item)
                        .font(.appCaption)
                        .foregroundStyle(.farBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.farBlue.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
                }
            }
        }
    }
}
