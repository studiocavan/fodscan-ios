import SwiftUI

private struct PrepItem: Identifiable {
    let id = UUID()
    let input: String
    let result: FodmapResult
}

private struct MealTemplate {
    let name: String
    let effort: String
    let sfSymbol: String
    let ingredients: [String]
}

private let mealTemplates: [MealTemplate] = [
    // Quick
    MealTemplate(
        name: "Greek Salad",
        effort: "~10 min",
        sfSymbol: "leaf.fill",
        ingredients: ["cucumber", "tomato", "bell pepper", "lettuce", "olive oil", "vinegar", "salt", "black pepper"]
    ),
    MealTemplate(
        name: "Simple Omelette",
        effort: "~15 min",
        sfSymbol: "flame",
        ingredients: ["egg", "butter", "spinach", "salt", "black pepper"]
    ),
    MealTemplate(
        name: "Dalmatian Grilled Fish",
        effort: "~20 min",
        sfSymbol: "fish",
        ingredients: ["sea bass", "potato", "olive oil", "lemon", "salt", "black pepper"]
    ),
    MealTemplate(
        name: "Fish Tacos",
        effort: "~20 min",
        sfSymbol: "fork.knife",
        ingredients: ["cod", "cabbage", "tomato", "lettuce", "olive oil", "vinegar", "salt", "black pepper"]
    ),
    // Medium
    MealTemplate(
        name: "Shakshuka",
        effort: "~25 min",
        sfSymbol: "sun.horizon.fill",
        ingredients: ["egg", "tomato", "bell pepper", "olive oil", "salt", "black pepper"]
    ),
    MealTemplate(
        name: "Chicken Taco Bowl",
        effort: "~25 min",
        sfSymbol: "fork.knife.circle",
        ingredients: ["rice", "chicken", "tomato", "bell pepper", "lettuce", "olive oil", "salt", "black pepper"]
    ),
    MealTemplate(
        name: "Quinoa Tabbouleh",
        effort: "~25 min",
        sfSymbol: "leaf",
        ingredients: ["quinoa", "tomato", "cucumber", "spinach", "olive oil", "vinegar", "salt"]
    ),
    MealTemplate(
        name: "Chicken Rice Bowl",
        effort: "~30 min",
        sfSymbol: "timer",
        ingredients: ["rice", "chicken", "bell pepper", "carrot", "zucchini", "soy sauce", "sesame oil", "salt"]
    ),
    MealTemplate(
        name: "Baked Salmon & Veg",
        effort: "~35 min",
        sfSymbol: "fish.fill",
        ingredients: ["salmon", "zucchini", "tomato", "bell pepper", "olive oil", "salt", "black pepper"]
    ),
    // Longer
    MealTemplate(
        name: "Chicken Paprikash",
        effort: "~45 min",
        sfSymbol: "flame.fill",
        ingredients: ["chicken", "tomato", "bell pepper", "olive oil", "sour cream", "salt", "black pepper"]
    ),
    MealTemplate(
        name: "Stuffed Bell Peppers",
        effort: "~50 min",
        sfSymbol: "circle.grid.2x2.fill",
        ingredients: ["bell pepper", "rice", "beef", "tomato", "olive oil", "salt", "black pepper"]
    ),
    MealTemplate(
        name: "Roast Chicken & Veg",
        effort: "~1 hour",
        sfSymbol: "clock",
        ingredients: ["chicken", "potato", "carrot", "zucchini", "olive oil", "salt", "black pepper"]
    ),
    MealTemplate(
        name: "Peka-Style Chicken",
        effort: "~2 hours",
        sfSymbol: "clock.arrow.2.circlepath",
        ingredients: ["chicken", "potato", "carrot", "zucchini", "tomato", "bell pepper", "olive oil", "salt", "black pepper"]
    ),
    MealTemplate(
        name: "Pasticada",
        effort: "~2 hours",
        sfSymbol: "clock.badge.checkmark",
        ingredients: ["beef", "carrot", "potato", "tomato", "olive oil", "vinegar", "salt", "black pepper"]
    ),
]

struct MealPrepView: View {
    @Environment(ScannerViewModel.self) private var viewModel
    @State private var ingredientText = ""
    @State private var items: [PrepItem] = []
    @FocusState private var fieldFocused: Bool

    private var suggestions: [FodmapEntry] {
        let q = ingredientText.trimmingCharacters(in: .whitespaces).lowercased()
        guard q.count >= 2 else { return [] }
        return Array(
            viewModel.entries.filter {
                $0.name.localizedCaseInsensitiveContains(q) ||
                $0.aliases.contains { $0.localizedCaseInsensitiveContains(q) }
            }
            .sorted { a, b in
                // Prioritise prefix matches over contains
                let aPrefix = a.name.lowercased().hasPrefix(q)
                let bPrefix = b.name.lowercased().hasPrefix(q)
                if aPrefix != bPrefix { return aPrefix }
                return a.name < b.name
            }
            .prefix(5)
        )
    }

    private var combinedVerdict: VerdictStatus {
        items.map(\.result.verdict).max() ?? .safe
    }

    var body: some View {
        VStack(spacing: 0) {
            if !items.isEmpty {
                verdictBanner
            }

            inputRow

            Divider()

            if !suggestions.isEmpty {
                suggestionsView
            } else if items.isEmpty {
                templatesView
            } else {
                ingredientList
            }
        }
        .navigationTitle("Meal Prep")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(mealTemplates, id: \.name) { template in
                        Button("\(template.name) (\(template.effort))") {
                            loadTemplate(template)
                        }
                    }
                } label: {
                    Label("Templates", systemImage: "fork.knife.circle")
                }
            }
            if !items.isEmpty {
                ToolbarItem(placement: .destructiveAction) {
                    Button("Clear All", role: .destructive) { items = [] }
                }
            }
        }
    }

    // MARK: - Subviews

    private var inputRow: some View {
        HStack(spacing: 10) {
            TextField("Add an ingredient…", text: $ingredientText)
                .textFieldStyle(.roundedBorder)
                .focused($fieldFocused)
                .autocorrectionDisabled()
                .onSubmit { addIngredient(name: ingredientText) }
            Button { addIngredient(name: ingredientText) } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        ingredientText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color.secondary : Color.accentColor
                    )
            }
            .disabled(ingredientText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var verdictBanner: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(combinedVerdict.color)
                .frame(width: 10, height: 10)
            Text("Overall: \(combinedVerdict.label)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(combinedVerdict.color)
            Spacer()
            Text("\(items.count) ingredient\(items.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(combinedVerdict.color.opacity(0.1))
    }

    private var suggestionsView: some View {
        VStack(spacing: 0) {
            ForEach(suggestions, id: \.name) { entry in
                Button { addIngredient(name: entry.name) } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(entry.status.color)
                            .frame(width: 8, height: 8)
                        Text(entry.name.capitalized)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(entry.status.label)
                            .font(.caption)
                            .foregroundStyle(entry.status.color)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 13)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading)
            }
            Spacer()
        }
        .frame(maxHeight: .infinity)
    }

    private var templatesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Start from a template")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                ForEach(mealTemplates, id: \.name) { template in
                    Button { loadTemplate(template) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: template.sfSymbol)
                                .font(.title3)
                                .foregroundStyle(.orange)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(template.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text(template.ingredients.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(template.effort)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 60)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var ingredientList: some View {
        List {
            ForEach(items) { item in
                PrepItemRow(item: item)
            }
            .onDelete { offsets in items.remove(atOffsets: offsets) }
        }
        .listStyle(.plain)
    }

    // MARK: - Actions

    private func addIngredient(name: String) {
        let text = name.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let result = viewModel.evaluate(text)
        items.append(PrepItem(input: text, result: result))
        ingredientText = ""
        fieldFocused = false
    }

    private func loadTemplate(_ template: MealTemplate) {
        items = template.ingredients.map { name in
            PrepItem(input: name, result: viewModel.evaluate(name))
        }
    }
}

private struct PrepItemRow: View {
    let item: PrepItem

    private var matchSummary: String {
        let flagged = item.result.matches.filter { $0.entry.status != .safe }
        if flagged.isEmpty {
            return item.result.verdict == .unknown ? "Not in FODMAP database" : "No triggers found"
        }
        return flagged.map { "\($0.entry.name) (\($0.entry.status.label))" }.joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.result.verdict.color)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.input)
                    .font(.body)
                Text(matchSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(item.result.verdict.label)
                .font(.caption.weight(.medium))
                .foregroundStyle(item.result.verdict.color)
        }
        .padding(.vertical, 2)
    }
}
