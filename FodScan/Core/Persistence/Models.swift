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
    var ingredientsText: String?

    init(
        date: Date = .now,
        productName: String?,
        barcode: String?,
        verdict: String,
        flaggedIngredients: [String],
        ingredientsText: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.productName = productName
        self.barcode = barcode
        self.verdict = verdict
        self.flaggedIngredients = flaggedIngredients
        self.ingredientsText = ingredientsText
    }

    var verdictStatus: VerdictStatus {
        VerdictStatus(rawValue: verdict) ?? .unknown
    }
}

@Model
final class UnknownIngredient {
    var token: String
    var date: Date
    var scanContext: String?
    var rawText: String?

    init(token: String, scanContext: String? = nil, rawText: String? = nil) {
        self.token = token
        self.date = .now
        self.scanContext = scanContext
        self.rawText = rawText
    }
}

@Model
final class IngredientOverride {
    var name: String
    var aliases: [String]
    var statusRaw: String
    var category: String
    var notes: String
    var addedDate: Date

    init(name: String, aliases: [String], statusRaw: String, category: String, notes: String) {
        self.name = name
        self.aliases = aliases
        self.statusRaw = statusRaw
        self.category = category
        self.notes = notes
        self.addedDate = .now
    }

    var status: VerdictStatus { VerdictStatus(rawValue: statusRaw) ?? .unknown }

    func asFodmapEntry() -> FodmapEntry {
        FodmapEntry(name: name, aliases: aliases, status: status, category: category, notes: notes.isEmpty ? nil : notes)
    }
}

@Model
final class VerdictFeedback {
    var date: Date
    var productName: String?
    var engineVerdict: String
    var flaggedIngredients: [String]
    var userNote: String

    init(productName: String?, engineVerdict: String, flaggedIngredients: [String], userNote: String) {
        self.date = .now
        self.productName = productName
        self.engineVerdict = engineVerdict
        self.flaggedIngredients = flaggedIngredients
        self.userNote = userNote
    }
}
