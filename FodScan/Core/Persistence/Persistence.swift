import SwiftData
import Foundation

extension ModelContainer {
    static let fodScan: ModelContainer = {
        let schema = Schema([ScanRecord.self, UnknownIngredient.self, VerdictFeedback.self, IngredientOverride.self])
        let config = ModelConfiguration(schema: schema)
        return try! ModelContainer(for: schema, configurations: [config])
    }()
}
