import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var unknownIngredients: [UnknownIngredient]
    @Query private var verdictFeedback: [VerdictFeedback]
    @Query private var overrides: [IngredientOverride]
    @Environment(\.modelContext) private var modelContext
    @State private var showingClearConfirm = false
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var pendingSuggestions: [Any] = []  // [RulesetSuggestion] at runtime
    @State private var showingSuggestions = false

    private var exportString: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let payload = ResearchExport(
            exportedAt: .now,
            unknownIngredients: unknownIngredients.map {
                .init(token: $0.token, date: $0.date, context: $0.scanContext, rawText: $0.rawText)
            },
            verdictFeedback: verdictFeedback.map {
                .init(date: $0.date, productName: $0.productName, engineVerdict: $0.engineVerdict,
                      flaggedIngredients: $0.flaggedIngredients, note: $0.userNote)
            },
            approvedOverrides: overrides.map {
                .init(name: $0.name, aliases: $0.aliases, status: $0.statusRaw,
                      category: $0.category, notes: $0.notes, addedDate: $0.addedDate)
            }
        )
        return (try? encoder.encode(payload)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }

    var body: some View {
        Form {
            researchSection
            dataSourcesSection
            aboutSection
            legalSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Delete all research data?",
            isPresented: $showingClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                unknownIngredients.forEach { modelContext.delete($0) }
                verdictFeedback.forEach { modelContext.delete($0) }
            }
        }
        .alert("Analysis Failed", isPresented: .constant(analysisError != nil)) {
            Button("OK") { analysisError = nil }
        } message: {
            Text(analysisError ?? "")
        }
        .sheet(isPresented: $showingSuggestions) {
            if #available(iOS 26, *) {
                SuggestionsReviewView(
                    suggestions: pendingSuggestions as! [RulesetSuggestion],
                    onSave: { saveApproved($0) }
                )
            }
        }
    }

    // MARK: - Sections

    private var researchSection: some View {
        Section {
            NavigationLink {
                UnknownIngredientsListView()
            } label: {
                LabeledContent("Unknown Ingredients", value: "\(unknownIngredients.count)")
            }
            NavigationLink {
                VerdictFeedbackListView()
            } label: {
                LabeledContent("Accuracy Reports", value: "\(verdictFeedback.count)")
            }
            NavigationLink {
                OverridesListView()
            } label: {
                LabeledContent("Ruleset Overrides", value: "\(overrides.count)")
            }

            analyzeButton

            ShareLink(
                item: exportString,
                subject: Text("FodScan Research Data"),
                message: Text("Unknowns, feedback, and approved overrides for FODMAP engine review.")
            ) {
                Label("Export as JSON", systemImage: "square.and.arrow.up")
            }
            .disabled(unknownIngredients.isEmpty && verdictFeedback.isEmpty && overrides.isEmpty)

            Button("Clear Unknowns & Feedback", role: .destructive) {
                showingClearConfirm = true
            }
            .disabled(unknownIngredients.isEmpty && verdictFeedback.isEmpty)
        } header: {
            Text("Research & Feedback")
        } footer: {
            Text("Unknowns are captured automatically on each scan. Flag inaccurate results with the report button on the verdict screen. Apple Intelligence analyzes this data and suggests ruleset additions — you review each one before it takes effect.")
        }
    }

    @ViewBuilder
    private var analyzeButton: some View {
        if #available(iOS 26, *) {
            switch OnDeviceLLMClient.availability {
            case .available:
                Button {
                    Task { await runAnalysis() }
                } label: {
                    if isAnalyzing {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text("Analyzing…")
                        }
                    } else {
                        Label("Analyze with Apple Intelligence", systemImage: "apple.intelligence")
                    }
                }
                .disabled(isAnalyzing || (unknownIngredients.isEmpty && verdictFeedback.isEmpty))
            case .notEnabled:
                Label("Enable Apple Intelligence in Settings to use this feature.", systemImage: "apple.intelligence")
                    .font(.caption).foregroundStyle(.secondary)
            case .deviceNotEligible:
                EmptyView()
            case .notReady:
                Label("Apple Intelligence model is downloading…", systemImage: "apple.intelligence")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var dataSourcesSection: some View {
        Section("Data Sources") {
            LabeledContent("FODMAP Ruleset", value: "2026-05-12")
            Link(destination: URL(string: "https://world.openfoodfacts.org")!) {
                Label("Open Food Facts", systemImage: "globe")
            }
            Text("Barcode data from Open Food Facts, licensed under ODbL. Data may be incomplete.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "1.0 (beta)")
            Link(destination: URL(string: "https://github.com/studiocavan/fodscan-ios")!) {
                Label("Source on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        }
    }

    private var legalSection: some View {
        Section {
            Link(destination: URL(string: "https://github.com/studiocavan/fodscan-ios/blob/main/PRIVACY.md")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
        } header: {
            Text("Legal")
        } footer: {
            Text("FodScan is a dietary reference tool and does not provide medical advice. FODMAP information is based on Monash University research and is for informational purposes only. Consult a registered dietitian or doctor before making dietary changes.")
                .font(.caption)
        }
    }

    // MARK: - Analysis

    @available(iOS 26, *)
    private func runAnalysis() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            let suggestions = try await OnDeviceLLMClient().suggestEntries(
                unknowns: Array(unknownIngredients),
                feedback: Array(verdictFeedback)
            )
            if suggestions.isEmpty {
                analysisError = "No suggestions generated. Try adding more scan data first."
            } else {
                pendingSuggestions = suggestions
                showingSuggestions = true
            }
        } catch {
            analysisError = error.localizedDescription
        }
    }

    @available(iOS 26, *)
    private func saveApproved(_ suggestions: [RulesetSuggestion]) {
        for s in suggestions {
            modelContext.insert(IngredientOverride(
                name: s.name,
                aliases: s.aliases,
                statusRaw: s.status,
                category: s.category,
                notes: s.notes
            ))
        }
    }
}

// MARK: - Suggestions review sheet

@available(iOS 26, *)
private struct SuggestionsReviewView: View {
    let suggestions: [RulesetSuggestion]
    let onSave: ([RulesetSuggestion]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var approved: Set<String> = []

    var body: some View {
        NavigationStack {
            List(suggestions, id: \.name) { suggestion in
                Button { toggle(suggestion.name) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: approved.contains(suggestion.name) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(approved.contains(suggestion.name) ? .green : .secondary)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(suggestion.name.capitalized).font(.body.weight(.medium))
                                Spacer()
                                let status = VerdictStatus(rawValue: suggestion.status) ?? .unknown
                                Text(status.label)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(status.color)
                                    .padding(.horizontal, 7).padding(.vertical, 2)
                                    .background(status.color.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            Text(suggestion.category.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption).foregroundStyle(.secondary)
                            if !suggestion.notes.isEmpty {
                                Text(suggestion.notes).font(.caption).foregroundStyle(.secondary)
                            }
                            if !suggestion.aliases.isEmpty {
                                Text("Also: " + suggestion.aliases.joined(separator: ", "))
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("AI Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add \(approved.count)") {
                        onSave(suggestions.filter { approved.contains($0.name) })
                        dismiss()
                    }
                    .disabled(approved.isEmpty)
                }
            }
        }
    }

    private func toggle(_ name: String) {
        if approved.contains(name) { approved.remove(name) } else { approved.insert(name) }
    }
}

// MARK: - Detail lists

struct UnknownIngredientsListView: View {
    @Query(sort: \UnknownIngredient.date, order: .reverse) private var items: [UnknownIngredient]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.token).font(.body.weight(.medium))
                    if let context = item.scanContext {
                        Text(context).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(item.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2).foregroundStyle(.tertiary)
                }
                .padding(.vertical, 2)
            }
            .onDelete { offsets in offsets.map { items[$0] }.forEach { modelContext.delete($0) } }
        }
        .navigationTitle("Unknown Ingredients")
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if items.isEmpty {
                ContentUnavailableView("No Data Yet", systemImage: "questionmark.circle",
                    description: Text("Unknown ingredients are captured automatically on each scan."))
            }
        }
    }
}

struct VerdictFeedbackListView: View {
    @Query(sort: \VerdictFeedback.date, order: .reverse) private var items: [VerdictFeedback]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(item.productName ?? "Manual scan").font(.body.weight(.medium))
                        Spacer()
                        Text(item.engineVerdict.capitalized)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(VerdictStatus(rawValue: item.engineVerdict)?.color ?? .secondary)
                    }
                    Text(item.userNote).font(.caption).foregroundStyle(.secondary)
                    Text(item.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2).foregroundStyle(.tertiary)
                }
                .padding(.vertical, 2)
            }
            .onDelete { offsets in offsets.map { items[$0] }.forEach { modelContext.delete($0) } }
        }
        .navigationTitle("Accuracy Reports")
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if items.isEmpty {
                ContentUnavailableView("No Reports Yet", systemImage: "flag",
                    description: Text("Tap the flag button on any scan result to report an inaccuracy."))
            }
        }
    }
}

struct OverridesListView: View {
    @Query(sort: \IngredientOverride.addedDate, order: .reverse) private var items: [IngredientOverride]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(items) { item in
                HStack(spacing: 12) {
                    Circle().fill(item.status.color).frame(width: 9, height: 9)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name.capitalized).font(.body.weight(.medium))
                        Text(item.category.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(item.status.label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(item.status.color)
                }
                .padding(.vertical, 2)
            }
            .onDelete { offsets in offsets.map { items[$0] }.forEach { modelContext.delete($0) } }
        }
        .navigationTitle("Ruleset Overrides")
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if items.isEmpty {
                ContentUnavailableView("No Overrides Yet", systemImage: "wand.and.stars",
                    description: Text("Approved Apple Intelligence suggestions appear here and take effect immediately in the scanner."))
            }
        }
    }
}

// MARK: - Export model

private struct ResearchExport: Codable {
    let exportedAt: Date
    let unknownIngredients: [UnknownItem]
    let verdictFeedback: [FeedbackItem]
    let approvedOverrides: [OverrideItem]

    struct UnknownItem: Codable {
        let token: String; let date: Date; let context: String?; let rawText: String?
    }
    struct FeedbackItem: Codable {
        let date: Date; let productName: String?; let engineVerdict: String
        let flaggedIngredients: [String]; let note: String
    }
    struct OverrideItem: Codable {
        let name: String; let aliases: [String]; let status: String
        let category: String; let notes: String; let addedDate: Date
    }
}
