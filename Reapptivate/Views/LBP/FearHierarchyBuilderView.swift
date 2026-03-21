import SwiftUI

struct FearHierarchyBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: LbpEnhancementsViewModel
    @AppStorage("appLanguage") private var appLanguage = "de"

    @State private var items: [BuilderItem] = []
    @State private var isSaving = false
    @State private var showSuggestions = true
    @State private var saveTrigger = false
    @State private var validationError: String?

    private var suggestions: [String] {
        appLanguage == "en"
            ? ["Heavy lifting", "Prolonged sitting", "Exercise", "Bending", "Climbing stairs", "Gardening", "Carrying groceries", "Running/Jogging"]
            : ["Schweres Heben", "Langes Sitzen", "Sport treiben", "Bucken", "Treppensteigen", "Gartenarbeit", "Einkaufen tragen", "Laufen/Joggen"]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text(appLanguage == "en"
                            ? "Create a list of activities that you fear or avoid."
                            : "Erstellen Sie eine Liste von Aktivitäten, vor denen Sie Angst haben oder die Sie vermeiden.")
                            .font(.appSubheadline)
                            .foregroundStyle(.textSecondary)
                        Text(appLanguage == "en"
                            ? "Rate each activity with a fear level from 0 (no fear) to 10 (maximum fear)."
                            : "Bewerten Sie jede Aktivität mit einem Angst-Level von 0 (keine Angst) bis 10 (maximale Angst).")
                            .font(.appSubheadline)
                            .foregroundStyle(.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .infoBoxStyle(color: .farBlue)

                    // Suggested activities
                    if showSuggestions && items.count < 3 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(appLanguage == "en" ? "Suggestions" : "Vorschläge")
                                .font(.appCaptionMedium)
                                .foregroundStyle(.textSecondary)

                            FlowLayoutSuggestions(items: unusedSuggestions) { suggestion in
                                addItem(name: suggestion)
                            }
                        }
                    }

                    // Items
                    ForEach(items.indices, id: \.self) { index in
                        if items.indices.contains(index) {
                            BuilderItemCard(
                                item: $items[index],
                                rank: index + 1,
                                onMoveUp: index > 0 ? { moveItem(from: index, to: index - 1) } : nil,
                                onMoveDown: index < items.count - 1 ? { moveItem(from: index, to: index + 1) } : nil,
                                onDelete: { items.remove(at: index) }
                            )
                        }
                    }

                    // Add button
                    Button {
                        addItem(name: "")
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                            Text(appLanguage == "en" ? "Add activity" : "Aktivität hinzufügen")
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

                    // Validation error
                    if let error = validationError {
                        Text(error)
                            .font(.appCaption)
                            .foregroundStyle(.painRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                                    Text(appLanguage == "en" ? "Save hierarchy" : "Hierarchie speichern")
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
            .navigationTitle(appLanguage == "en" ? "Fear Hierarchy" : "Angst-Hierarchie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(appLanguage == "en" ? "Cancel" : "Abbrechen") { dismiss() }
                }
            }
            .conditionalHaptic(.success, trigger: saveTrigger)
        }
    }

    // MARK: - Helpers

    private var canSave: Bool {
        validate() == nil
    }

    private func validate() -> String? {
        guard !items.isEmpty else {
            return appLanguage == "en"
                ? "Add at least one activity."
                : "Fügen Sie mindestens eine Aktivität hinzu."
        }

        guard items.count >= 3 else {
            return appLanguage == "en"
                ? "A hierarchy requires at least 3 activities."
                : "Eine Hierarchie benötigt mindestens 3 Aktivitäten."
        }

        for (index, item) in items.enumerated() {
            let trimmed = item.name.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                return appLanguage == "en"
                    ? "Activity \(index + 1) needs a name."
                    : "Aktivität \(index + 1) benötigt einen Namen."
            }
            if trimmed.count > 50 {
                return appLanguage == "en"
                    ? "Activity \(index + 1) is too long (max. 50 characters)."
                    : "Aktivität \(index + 1) ist zu lang (max. 50 Zeichen)."
            }
        }

        return nil
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
        // Validate before saving
        if let error = validate() {
            validationError = error
            return
        }
        validationError = nil

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
            saveTrigger.toggle()
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

    @AppStorage("appLanguage") private var appLanguage = "de"
    @ScaledMetric(relativeTo: .caption) private var rankCircleSize: CGFloat = 22

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
                    .accessibilityLabel(appLanguage == "en" ? "Move up" : "Nach oben verschieben")

                    Text("\(rank)")
                        .font(.appCaptionBold)
                        .foregroundStyle(.white)
                        .frame(width: rankCircleSize, height: rankCircleSize)
                        .background(ratingColor)
                        .clipShape(Circle())

                    Button { onMoveDown?() } label: {
                        Image(systemName: "chevron.down")
                            .font(.appCaption2)
                            .foregroundStyle(onMoveDown != nil ? .textSecondary : .clear)
                    }
                    .disabled(onMoveDown == nil)
                    .accessibilityLabel(appLanguage == "en" ? "Move down" : "Nach unten verschieben")
                }

                VStack(spacing: 8) {
                    // Activity name
                    TextField(appLanguage == "en" ? "Activity" : "Aktivität", text: $item.name)
                        .font(.appSubheadline)
                        .padding(10)
                        .background(Color.appBg)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous))
                        .submitLabel(.done)

                    // Fear rating slider
                    HStack(spacing: 8) {
                        Text(appLanguage == "en" ? "Fear:" : "Angst:")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)

                        Slider(value: Binding(
                            get: { Double(item.fearRating) },
                            set: { item.fearRating = Int($0) }
                        ), in: 0...10, step: 1)
                        .tint(ratingColor)
                        .accessibilityLabel(appLanguage == "en" ? "Fear rating" : "Angst-Bewertung")
                        .accessibilityValue(appLanguage == "en" ? "\(item.fearRating) of 10" : "\(item.fearRating) von 10")

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
                .accessibilityLabel(appLanguage == "en" ? "Delete" : "Löschen")
            }
        }
        .cardStyle(padding: 12)
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
