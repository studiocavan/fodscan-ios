import SwiftData
import Foundation

@Model
final class ScanRecord {
    var id: UUID
    var date: Date
    var productName: String?
    var barcode: String?
    var verdict: String
    var flaggedIngredients: [String]

    init(
        date: Date = .now,
        productName: String?,
        barcode: String?,
        verdict: String,
        flaggedIngredients: [String]
    ) {
        self.id = UUID()
        self.date = date
        self.productName = productName
        self.barcode = barcode
        self.verdict = verdict
        self.flaggedIngredients = flaggedIngredients
    }

    var verdictStatus: VerdictStatus {
        VerdictStatus(rawValue: verdict) ?? .unknown
    }
}
