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
    let steps: [String]
}

private let mealTemplates: [MealTemplate] = [
    // Quick
    MealTemplate(
        name: "Greek Salad",
        effort: "~10 min",
        sfSymbol: "leaf.fill",
        ingredients: ["cucumber", "tomato", "bell pepper", "lettuce", "olive oil", "vinegar", "salt", "black pepper"],
        steps: [
            "Dice cucumber, tomato, and bell pepper into bite-sized chunks.",
            "Tear lettuce into a large bowl.",
            "Drizzle with olive oil and a splash of vinegar.",
            "Season with salt and black pepper, toss and serve.",
        ]
    ),
    MealTemplate(
        name: "Simple Omelette",
        effort: "~15 min",
        sfSymbol: "flame",
        ingredients: ["egg", "butter", "spinach", "salt", "black pepper"],
        steps: [
            "Whisk eggs with a pinch of salt and black pepper.",
            "Melt butter in a non-stick pan over medium heat.",
            "Add spinach and cook 1 minute until wilted.",
            "Pour in the eggs and cook until just set, then fold and serve.",
        ]
    ),
    MealTemplate(
        name: "Dalmatian Grilled Fish",
        effort: "~20 min",
        sfSymbol: "fish",
        ingredients: ["sea bass", "potato", "olive oil", "lemon", "salt", "black pepper"],
        steps: [
            "Parboil potatoes until just tender, about 10 minutes.",
            "Season fish with olive oil, lemon juice, salt, and pepper.",
            "Grill or pan-fry fish for 3–4 minutes per side.",
            "Serve fish over the potatoes with a drizzle of olive oil.",
        ]
    ),
    MealTemplate(
        name: "Fish Tacos",
        effort: "~20 min",
        sfSymbol: "fork.knife",
        ingredients: ["cod", "cabbage", "tomato", "lettuce", "olive oil", "vinegar", "salt", "black pepper"],
        steps: [
            "Season cod with salt, pepper, and a drizzle of olive oil.",
            "Pan-fry cod 3–4 minutes per side until flaky; break into chunks.",
            "Use corn tortillas (low FODMAP). Warm them in a dry pan.",
            "Fill with fish, shredded cabbage, diced tomato, and a splash of vinegar.",
        ]
    ),
    // Medium
    MealTemplate(
        name: "Shakshuka",
        effort: "~25 min",
        sfSymbol: "sun.horizon.fill",
        ingredients: ["egg", "tomato", "bell pepper", "olive oil", "salt", "black pepper"],
        steps: [
            "Heat olive oil in a skillet; add diced bell pepper and cook 3 minutes.",
            "Add diced tomatoes, salt, and pepper; simmer 10 minutes until thickened.",
            "Make wells in the sauce and crack eggs into them.",
            "Cover and cook 5–7 minutes until whites are set. Serve from the pan.",
        ]
    ),
    MealTemplate(
        name: "Chicken Taco Bowl",
        effort: "~25 min",
        sfSymbol: "fork.knife.circle",
        ingredients: ["rice", "chicken", "tomato", "bell pepper", "lettuce", "olive oil", "salt", "black pepper"],
        steps: [
            "Cook rice according to package instructions.",
            "Season chicken with salt, pepper, and olive oil; cook in a hot pan 5–6 minutes per side. Rest and slice.",
            "Sauté diced bell pepper and tomato in the same pan for 3 minutes.",
            "Assemble bowls with rice, sliced chicken, sautéed veg, and shredded lettuce.",
        ]
    ),
    MealTemplate(
        name: "Quinoa Tabbouleh",
        effort: "~25 min",
        sfSymbol: "leaf",
        ingredients: ["quinoa", "tomato", "cucumber", "spinach", "olive oil", "vinegar", "salt"],
        steps: [
            "Cook quinoa in water for 15 minutes; spread on a tray to cool.",
            "Finely dice tomato and cucumber; roughly chop spinach.",
            "Combine cooled quinoa with vegetables, olive oil, and a splash of vinegar.",
            "Season with salt, toss well, and rest 10 minutes before serving.",
        ]
    ),
    MealTemplate(
        name: "Chicken Rice Bowl",
        effort: "~30 min",
        sfSymbol: "timer",
        ingredients: ["rice", "chicken", "bell pepper", "carrot", "zucchini", "soy sauce", "sesame oil", "salt"],
        steps: [
            "Cook rice according to package instructions.",
            "Slice chicken; marinate in soy sauce and sesame oil for 10 minutes.",
            "Stir-fry carrot, zucchini, and bell pepper in a hot pan 3–4 minutes.",
            "Add chicken and cook through, about 5 minutes. Serve over rice.",
        ]
    ),
    MealTemplate(
        name: "Lamb Ragù Noodles",
        effort: "~30 min",
        sfSymbol: "fork.knife",
        ingredients: ["lamb", "tomato", "rice noodles", "olive oil", "cheddar", "salt", "black pepper"],
        steps: [
            "Cut lamb into small chunks; season with salt and pepper only.",
            "Brown lamb in olive oil over high heat, then set aside.",
            "Reduce to medium heat. Add paprika and cumin to the pan and stir for 30 seconds until fragrant.",
            "Add diced tomatoes, oregano, chili flakes, and a bay leaf; simmer 10 minutes.",
            "Return lamb and cook 15 more minutes until rich and thick. Remove bay leaf.",
            "Cook rice noodles per package. Toss with ragù and finish with grated cheddar.",
        ]
    ),
    MealTemplate(
        name: "Baked Salmon & Veg",
        effort: "~35 min",
        sfSymbol: "fish.fill",
        ingredients: ["salmon", "zucchini", "tomato", "bell pepper", "olive oil", "salt", "black pepper"],
        steps: [
            "Preheat oven to 200°C (400°F).",
            "Slice zucchini, tomato, and bell pepper; spread on a baking tray with olive oil, salt, and pepper.",
            "Lay salmon on top and season.",
            "Bake 18–20 minutes until salmon is just cooked through.",
        ]
    ),
    // Longer
    MealTemplate(
        name: "Chicken Paprikash",
        effort: "~45 min",
        sfSymbol: "flame.fill",
        ingredients: ["chicken", "tomato", "bell pepper", "olive oil", "sour cream", "salt", "black pepper"],
        steps: [
            "Season chicken pieces with salt and paprika.",
            "Brown chicken in olive oil over medium-high heat; set aside.",
            "Add diced tomato and bell pepper to the pan; cook 5 minutes.",
            "Return chicken, cover and simmer 25 minutes. Stir in sour cream off the heat.",
        ]
    ),
    MealTemplate(
        name: "Stuffed Bell Peppers",
        effort: "~50 min",
        sfSymbol: "circle.grid.2x2.fill",
        ingredients: ["bell pepper", "rice", "beef", "tomato", "olive oil", "salt", "black pepper"],
        steps: [
            "Preheat oven to 190°C (375°F). Cook rice until just underdone.",
            "Brown ground beef with diced tomato, olive oil, salt, and pepper.",
            "Mix beef with rice; stuff into halved bell peppers in a baking dish.",
            "Bake 30–35 minutes until peppers are tender.",
        ]
    ),
    MealTemplate(
        name: "Roast Chicken & Veg",
        effort: "~1 hour",
        sfSymbol: "clock",
        ingredients: ["chicken", "potato", "carrot", "zucchini", "olive oil", "salt", "black pepper"],
        steps: [
            "Preheat oven to 200°C (400°F).",
            "Chop potato, carrot, and zucchini into chunks; toss with olive oil, salt, and pepper.",
            "Place chicken pieces on top of vegetables in a roasting tray.",
            "Roast 45–50 minutes, turning vegetables halfway, until chicken is golden and cooked through.",
        ]
    ),
    MealTemplate(
        name: "Peka-Style Chicken",
        effort: "~2 hours",
        sfSymbol: "clock.arrow.2.circlepath",
        ingredients: ["chicken", "potato", "carrot", "zucchini", "tomato", "bell pepper", "olive oil", "salt", "black pepper"],
        steps: [
            "Chop all vegetables into large chunks.",
            "Layer vegetables in a heavy roasting tray; place chicken pieces on top.",
            "Drizzle generously with olive oil; season well with salt and pepper.",
            "Cover tightly with foil and roast at 180°C (350°F) for 1.5–2 hours until everything is very tender.",
        ]
    ),
    MealTemplate(
        name: "Pasticada",
        effort: "~2 hours",
        sfSymbol: "clock.badge.checkmark",
        ingredients: ["beef", "carrot", "potato", "tomato", "olive oil", "vinegar", "salt", "black pepper"],
        steps: [
            "Cut beef into large chunks; marinate in vinegar, olive oil, salt, and pepper for 30 minutes.",
            "Brown beef in olive oil over high heat; set aside.",
            "Add diced carrot, tomato, and potato to the pot; cook 5 minutes.",
            "Return beef, add water to half-cover; simmer covered 1.5 hours until very tender.",
        ]
    ),
]

// MARK: - Template browser

struct MealPrepView: View {
    var body: some View {
        List {
            ForEach(mealTemplates, id: \.name) { template in
                NavigationLink {
                    MealPrepRecipeView(template: template)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: template.sfSymbol)
                            .font(.title3)
                            .foregroundStyle(.orange)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(template.name)
                                .font(.body.weight(.medium))
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
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Meal Prep")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Recipe detail / ingredient checker

private enum RecipeTab { case ingredients, steps }

private struct MealPrepRecipeView: View {
    let template: MealTemplate
    @Environment(ScannerViewModel.self) private var viewModel
    @State private var tab: RecipeTab = .ingredients
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
            Picker("", selection: $tab) {
                Text("Ingredients").tag(RecipeTab.ingredients)
                Text("Steps").tag(RecipeTab.steps)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            if tab == .ingredients {
                if !items.isEmpty {
                    verdictBanner
                }
                inputRow
                Divider()
                if !suggestions.isEmpty {
                    suggestionsView
                } else {
                    ingredientList
                }
            } else {
                stepsView
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if tab == .ingredients && !items.isEmpty {
                ToolbarItem(placement: .destructiveAction) {
                    Button("Clear All", role: .destructive) { items = [] }
                }
            }
        }
        .task { loadTemplate() }
    }

    private var stepsView: some View {
        List {
            ForEach(Array(template.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    Text("\(index + 1)")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.orange)
                        .frame(width: 24, alignment: .center)
                    Text(step)
                        .font(.body)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
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

    private func loadTemplate() {
        items = template.ingredients.map { name in
            PrepItem(input: name, result: viewModel.evaluate(name))
        }
    }
}

// MARK: - Row

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
