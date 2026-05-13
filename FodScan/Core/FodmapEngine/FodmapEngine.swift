import Foundation

struct IngredientMatch {
    let token: String
    let entry: FodmapEntry
}

struct FodmapResult {
    let verdict: VerdictStatus
    let matches: [IngredientMatch]
}

struct FodmapEngine {
    private let entries: [FodmapEntry]
    private let normalizer = IngredientNormalizer()

    init(ruleset: Ruleset) {
        self.entries = ruleset.entries
    }

    func analyze(_ ingredientsText: String) -> FodmapResult {
        let tokens = normalizer.tokenize(ingredientsText)
        var matches: [IngredientMatch] = []

        for token in tokens {
            guard let entry = findMatch(for: token) else { continue }
            // one match per ruleset entry — highest severity token wins
            if let existing = matches.firstIndex(where: { $0.entry.name == entry.name }) {
                if entry.status > matches[existing].entry.status {
                    matches[existing] = IngredientMatch(token: token, entry: entry)
                }
            } else {
                matches.append(IngredientMatch(token: token, entry: entry))
            }
        }

        let verdict = matches.map(\.entry.status).max() ?? .unknown
        return FodmapResult(verdict: verdict, matches: matches)
    }

    private func findMatch(for token: String) -> FodmapEntry? {
        for entry in entries {
            if matchesWholeWord(token, word: entry.name) { return entry }
            for alias in entry.aliases where matchesWholeWord(token, word: alias) { return entry }
        }
        return nil
    }

    // Requires the match to start and end at a non-alphanumeric boundary so
    // "corn" doesn't fire inside "acorn" or "unicorn".
    private func matchesWholeWord(_ text: String, word: String) -> Bool {
        var searchStart = text.startIndex
        while let range = text.range(of: word, range: searchStart..<text.endIndex) {
            let before = range.lowerBound > text.startIndex
                ? text[text.index(before: range.lowerBound)] : nil
            let after = range.upperBound < text.endIndex
                ? text[range.upperBound] : nil
            let startOk = before.map { !$0.isLetter && !$0.isNumber } ?? true
            let endOk   = after.map  { !$0.isLetter && !$0.isNumber } ?? true
            if startOk && endOk { return true }
            searchStart = range.upperBound
        }
        return false
    }
}
