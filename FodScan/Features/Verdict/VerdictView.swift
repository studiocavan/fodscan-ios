import SwiftUI
import SwiftData

struct VerdictSheet: View {
    let result: FodmapResult
    let productName: String?
    let rawIngredientsText: String?
    let onDismiss: () -> Void

    @State private var explanation: String?
    @State private var isExplaining = false
    @State private var showingFeedback = false

    private var flaggedMatches: [IngredientMatch] {
        result.matches.filter { $0.entry.status != .safe }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Verdict banner
                VStack(spacing: 6) {
                    Text(result.verdict.label.uppercased())
                        .font(.system(size: 44, weight: .black))
                        .foregroundStyle(result.verdict.color)
                    if let name = productName, !name.isEmpty {
                        Text(name)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(result.verdict.color.opacity(0.12))

                if flaggedMatches.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                        Text("No known FODMAP triggers found.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    IngredientBreakdownView(matches: flaggedMatches)
                }

                // Apple Intelligence explanation
                if #available(iOS 26, *) {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        switch OnDeviceLLMClient.availability {
                        case .available:
                            if let text = explanation {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "apple.intelligence")
                                        .foregroundStyle(.secondary)
                                    Text(text)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            } else if isExplaining {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Explaining with Apple Intelligence…")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Button {
                                    Task { await fetchExplanation() }
                                } label: {
                                    Label("Explain with Apple Intelligence", systemImage: "apple.intelligence")
                                        .font(.subheadline)
                                }
                            }
                        case .notEnabled:
                            Label("Enable Apple Intelligence in Settings → Apple Intelligence & Siri to use this feature.", systemImage: "apple.intelligence")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        case .notReady:
                            Label("Apple Intelligence model is still downloading. Try again shortly.", systemImage: "apple.intelligence")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        case .deviceNotEligible:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
            .navigationTitle("Scan Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingFeedback = true } label: {
                        Label("Report", systemImage: "flag")
                    }
                    .tint(.orange)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Scan Again", action: onDismiss)
                }
            }
            .sheet(isPresented: $showingFeedback) {
                FeedbackSheet(result: result, productName: productName)
            }
        }
    }

    @available(iOS 26, *)
    private func fetchExplanation() async {
        isExplaining = true
        defer { isExplaining = false }
        explanation = try? await OnDeviceLLMClient().explain(
            result: result,
            productName: productName,
            rawIngredientsText: rawIngredientsText
        )
    }
}

private struct FeedbackSheet: View {
    let result: FodmapResult
    let productName: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Scan details") {
                    LabeledContent("Verdict", value: result.verdict.label)
                    if let name = productName, !name.isEmpty {
                        LabeledContent("Product", value: name)
                    }
                    let flagged = result.matches.map(\.entry.name)
                    if !flagged.isEmpty {
                        LabeledContent("Flagged", value: flagged.joined(separator: ", "))
                    }
                }
                Section {
                    TextField("What seems wrong?", text: $note, axis: .vertical)
                        .lineLimit(3...)
                } header: {
                    Text("Your note")
                } footer: {
                    Text("Stored locally. Export from Settings → Research to share with the developer.")
                }
            }
            .navigationTitle("Report Inaccuracy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        modelContext.insert(VerdictFeedback(
                            productName: productName,
                            engineVerdict: result.verdict.rawValue,
                            flaggedIngredients: result.matches.map(\.entry.name),
                            userNote: note
                        ))
                        dismiss()
                    }
                    .disabled(note.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct ErrorSheet: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                Spacer()
            }
            .navigationTitle("Not Found")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Scan Again", action: onDismiss)
                }
            }
        }
    }
}
