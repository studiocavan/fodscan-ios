import Foundation
import Observation

enum ScanMode: String, CaseIterable {
    case barcode = "Barcode"
    case ingredients = "Ingredients"
}

enum ScanState {
    case idle
    case loading
    case result(FodmapResult, productName: String?)
    case error(String)
}

@Observable
@MainActor
final class ScannerViewModel {
    var scanState: ScanState = .idle
    private(set) var lastBarcode: String?
    private(set) var scanResultID: UUID?
    private(set) var rawIngredientsText: String?

    private let offClient = OpenFoodFactsClient()
    private let engine: FodmapEngine

    init() {
        let ruleset = (try? RulesetLoader.load()) ?? Ruleset(version: "error", entries: [])
        engine = FodmapEngine(ruleset: ruleset)
    }

    func scan(barcode: String) async {
        guard barcode != lastBarcode else { return }
        lastBarcode = barcode
        scanState = .loading

        do {
            guard let product = try await offClient.product(for: barcode) else {
                scanState = .error("Product not found in Open Food Facts")
                return
            }
            guard let ingredientsText = product.ingredientsText, !ingredientsText.isEmpty else {
                scanState = .error("No ingredients listed for this product")
                return
            }
            let result = engine.analyze(ingredientsText)
            rawIngredientsText = ingredientsText
            scanState = .result(result, productName: product.productName)
            scanResultID = UUID()
        } catch {
            scanState = .error("Could not reach Open Food Facts. Check your connection.")
        }
    }

    func analyzeIngredients(text: String) {
        let result = engine.analyze(text)
        rawIngredientsText = text
        scanState = .result(result, productName: nil)
        scanResultID = UUID()
    }

    func evaluate(_ text: String) -> FodmapResult {
        engine.analyze(text)
    }

    func reset() {
        lastBarcode = nil
        rawIngredientsText = nil
        scanState = .idle
    }
}
