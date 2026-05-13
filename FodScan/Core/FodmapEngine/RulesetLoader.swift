import Foundation

struct FodmapEntry: Decodable {
    let name: String
    let aliases: [String]
    let status: VerdictStatus
    let category: String
    let notes: String?
}

struct Ruleset: Decodable {
    let version: String
    let entries: [FodmapEntry]
}

enum RulesetError: Error {
    case fileNotFound
}

struct RulesetLoader {
    static func load() throws -> Ruleset {
        guard let url = Bundle.main.url(forResource: "fodmap_ingredients", withExtension: "json") else {
            throw RulesetError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Ruleset.self, from: data)
    }
}
