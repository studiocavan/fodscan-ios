import Foundation

struct IngredientNormalizer {
    func tokenize(_ raw: String) -> [String] {
        var text = raw.lowercased()
        text = stripMayContain(text)
        text = stripContainsXPercent(text)
        return splitRespectingParens(text)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { stripTrailingPercentage($0) }
            .filter { !$0.isEmpty }
    }

    // "may contain traces of: peanuts" — strip everything after this phrase
    private func stripMayContain(_ text: String) -> String {
        let markers = ["may contain", "contains traces of", "produced in a facility"]
        for marker in markers {
            if let range = text.range(of: marker) {
                return String(text[..<range.lowerBound])
            }
        }
        return text
    }

    // "contains 2% or less of: x, y, z" — keep x, y, z but remove the preamble
    private func stripContainsXPercent(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"contains \d+\.?\d*%? or less of[:\s]*"#,
            with: "",
            options: .regularExpression
        )
    }

    // "garlic powder (2%)" -> "garlic powder"
    private func stripTrailingPercentage(_ token: String) -> String {
        token.replacingOccurrences(
            of: #"\s*\(\d+\.?\d*%\)$"#,
            with: "",
            options: .regularExpression
        )
    }

    // Split on commas, recursing into parenthetical sub-ingredient groups
    private func splitRespectingParens(_ text: String) -> [String] {
        var result: [String] = []
        var current = ""
        var depth = 0

        for char in text {
            switch char {
            case "(":
                depth += 1
                if depth == 1 {
                    let token = current.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !token.isEmpty { result.append(token) }
                    current = ""
                } else {
                    current.append(char)
                }
            case ")":
                depth -= 1
                if depth == 0 {
                    result.append(contentsOf: splitRespectingParens(current))
                    current = ""
                } else {
                    current.append(char)
                }
            case ",":
                if depth == 0 {
                    let token = current.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !token.isEmpty { result.append(token) }
                    current = ""
                } else {
                    current.append(char)
                }
            default:
                current.append(char)
            }
        }

        let last = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !last.isEmpty { result.append(last) }

        return result
    }
}
