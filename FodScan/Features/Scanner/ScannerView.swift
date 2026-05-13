import SwiftUI
import VisionKit

struct ScannerView: View {
    @Environment(ScannerViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @State private var mode: ScanMode = .ingredients
    @State private var scannedBarcode: String?
    @State private var detectedText: String?
    @State private var showingResult = false
    @State private var scanTask: Task<Void, Never>?
    @State private var isModeTransitioning = false

    var body: some View {
        ZStack {
            if !isModeTransitioning && DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                DataScannerRepresentable(mode: mode, scannedBarcode: $scannedBarcode, detectedText: $detectedText)
                    .id(mode)
                    .ignoresSafeArea()
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
                    }

                    if case .loading = viewModel.scanState {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Looking up product…")
                                .font(.subheadline)
                        }
                    }

                    Picker("Scan mode", selection: $mode) {
                        Text("Ingredients").tag(ScanMode.ingredients)
                        Text("Barcode ↗").tag(ScanMode.barcode)
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
            let record = ScanRecord(
                productName: productName,
                barcode: viewModel.lastBarcode,
                verdict: result.verdict.rawValue,
                flaggedIngredients: result.matches.map(\.entry.name)
            )
            modelContext.insert(record)
        }
        .onChange(of: mode) { _, _ in
            scanTask?.cancel()
            scanTask = nil
            scannedBarcode = nil
            detectedText = nil
            viewModel.reset()
            // Gate the new scanner behind a layout pass so the old AVCaptureSession
            // fully releases before the new one starts.
            isModeTransitioning = true
            Task {
                try? await Task.sleep(for: .milliseconds(250))
                isModeTransitioning = false
            }
        }
    }

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
