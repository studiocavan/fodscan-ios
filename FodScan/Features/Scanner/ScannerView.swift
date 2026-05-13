import SwiftUI
import SwiftData
import VisionKit

struct ScannerView: View {
    @Environment(ScannerViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var overrides: [IngredientOverride]
    @State private var mode: ScanMode = .ingredients
    @State private var scannedBarcode: String?
    @State private var detectedText: String?
    @State private var showingResult = false
    @State private var scanTask: Task<Void, Never>?
    @State private var isModeTransitioning = false

    // Lookup mode
    @State private var lookupText = ""
    @State private var lookupEntry: FodmapEntry?
    @FocusState private var lookupFocused: Bool

    private var lookupSuggestions: [FodmapEntry] {
        let q = lookupText.trimmingCharacters(in: .whitespaces).lowercased()
        guard q.count >= 2, lookupEntry == nil else { return [] }
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
            .prefix(4)
        )
    }

    var body: some View {
        ZStack {
            if mode == .lookup {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            } else if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                if !isModeTransitioning {
                    DataScannerRepresentable(mode: mode, scannedBarcode: $scannedBarcode, detectedText: $detectedText)
                        .id(mode)
                        .ignoresSafeArea()
                }
            } else {
                ContentUnavailableView(
                    "Scanner Unavailable",
                    systemImage: "barcode.viewfinder",
                    description: Text("This device does not support barcode scanning.")
                )
            }

            VStack {
                Spacer()

                VStack(spacing: 12) {
                    if mode == .ingredients {
                        if let text = detectedText {
                            Text(text.prefix(80) + (text.count > 80 ? "…" : ""))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button("Analyze Ingredients") {
                                viewModel.analyzeIngredients(text: text)
                                showingResult = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        } else {
                            Text("Point camera at the ingredient list")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if mode == .lookup {
                        lookupPanel
                    }

                    if case .loading = viewModel.scanState, mode != .lookup {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Looking up product…")
                                .font(.subheadline)
                        }
                    }

                    Picker("Scan mode", selection: $mode) {
                        Text("Ingredients").tag(ScanMode.ingredients)
                        Text("Barcode ↗").tag(ScanMode.barcode)
                        Text("Search").tag(ScanMode.lookup)
                    }
                    .pickerStyle(.segmented)

                    if mode == .barcode {
                        Label("Requires internet connection", systemImage: "wifi")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showingResult, onDismiss: {
            viewModel.reset()
            scannedBarcode = nil
            detectedText = nil
        }) {
            resultSheetContent
        }
        .onChange(of: scannedBarcode) { _, newValue in
            guard let barcode = newValue else { return }
            scanTask?.cancel()
            scanTask = Task {
                await viewModel.scan(barcode: barcode)
                guard !Task.isCancelled else { return }
                switch viewModel.scanState {
                case .result, .error: showingResult = true
                default: break
                }
            }
        }
        .onChange(of: viewModel.scanResultID) { _, _ in
            guard case .result(let result, let productName) = viewModel.scanState else { return }
            modelContext.insert(ScanRecord(
                productName: productName,
                barcode: viewModel.lastBarcode,
                verdict: result.verdict.rawValue,
                flaggedIngredients: result.matches.map(\.entry.name),
                ingredientsText: viewModel.rawIngredientsText
            ))
            let context = productName ?? "Manual scan"
            for token in result.unmatchedTokens {
                modelContext.insert(UnknownIngredient(
                    token: token,
                    scanContext: context,
                    rawText: viewModel.rawIngredientsText
                ))
            }
        }
        .task {
            viewModel.updateOverrides(overrides.map { $0.asFodmapEntry() })
        }
        .onChange(of: overrides) { _, newOverrides in
            viewModel.updateOverrides(newOverrides.map { $0.asFodmapEntry() })
        }
        .onChange(of: mode) { oldValue, newValue in
            scanTask?.cancel()
            scanTask = nil
            scannedBarcode = nil
            detectedText = nil
            lookupText = ""
            lookupEntry = nil
            viewModel.reset()
            // Only need the AVCaptureSession release delay when swapping between two camera modes
            let cameraModes: Set<ScanMode> = [.ingredients, .barcode]
            if cameraModes.contains(oldValue) && cameraModes.contains(newValue) {
                isModeTransitioning = true
                Task {
                    try? await Task.sleep(for: .milliseconds(250))
                    isModeTransitioning = false
                }
            }
        }
    }

    // MARK: - Lookup panel

    @ViewBuilder
    private var lookupPanel: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Type an ingredient…", text: $lookupText)
                .autocorrectionDisabled()
                .focused($lookupFocused)
                .onChange(of: lookupText) { _, _ in lookupEntry = nil }
            if !lookupText.isEmpty {
                Button {
                    lookupText = ""
                    lookupEntry = nil
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.systemBackground).opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 10))

        ForEach(lookupSuggestions, id: \.name) { entry in
            Button {
                lookupEntry = entry
                lookupText = entry.name.capitalized
                lookupFocused = false
            } label: {
                HStack(spacing: 10) {
                    Circle().fill(entry.status.color).frame(width: 8, height: 8)
                    Text(entry.name.capitalized).foregroundStyle(.primary).font(.subheadline)
                    Spacer()
                    Text(entry.status.label).font(.caption).foregroundStyle(entry.status.color)
                }
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
        }

        if let entry = lookupEntry {
            LookupEntryCard(entry: entry)
        }
    }

    // MARK: - Result sheet

    @ViewBuilder
    private var resultSheetContent: some View {
        switch viewModel.scanState {
        case .result(let result, let productName):
            VerdictSheet(result: result, productName: productName, rawIngredientsText: viewModel.rawIngredientsText) {
                showingResult = false
            }
        case .error(let message):
            ErrorSheet(message: message) {
                showingResult = false
            }
        default:
            EmptyView()
        }
    }
}

private struct LookupEntryCard: View {
    let entry: FodmapEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle().fill(entry.status.color).frame(width: 10, height: 10)
                Text(entry.name.capitalized).font(.body.weight(.semibold))
                Spacer()
                Text(entry.status.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(entry.status.color)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(entry.status.color.opacity(0.12))
                    .clipShape(Capsule())
            }
            Text(entry.category.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.caption).foregroundStyle(.secondary)
            if let notes = entry.notes {
                Text(notes).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground).opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
