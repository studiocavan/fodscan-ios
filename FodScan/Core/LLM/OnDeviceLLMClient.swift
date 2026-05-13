import Foundation
import FoundationModels

@available(iOS 26, *)
struct OnDeviceLLMClient {

    enum Availability {
        case available
        case notEnabled
        case deviceNotEligible
        case notReady
    }

    static var availability: Availability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(.appleIntelligenceNotEnabled):
            return .notEnabled
        case .unavailable(.deviceNotEligible):
            return .deviceNotEligible
        default:
            return .notReady
        }
    }

    static var isAvailable: Bool { availability == .available }

    // MARK: - Verdict explanation

    private let explainSession = LanguageModelSession(instructions: """
        You are a low-FODMAP diet assistant helping someone with SIBO manage their diet strictly. \
        Be concise — 2 to 4 sentences max. Plain language, no markdown. \
        Focus on what the flagged ingredients mean in practice and any nuance worth knowing.
        """)

    func explain(result: FodmapResult, productName: String?, rawIngredientsText: String?) async throws -> String {
        let flagged = result.matches.filter { $0.entry.status != .safe }
        let flags = flagged.map {
            "\($0.entry.name) (\($0.entry.status.label), \($0.entry.category.replacingOccurrences(of: "_", with: " ")))"
        }.joined(separator: "; ")

        var prompt = "Verdict: \(result.verdict.label)."
        if let name = productName, !name.isEmpty { prompt += " Product: \(name)." }
        if let raw = rawIngredientsText, !raw.isEmpty { prompt += " Full ingredient list: \(raw)." }
        if flags.isEmpty {
            prompt += " No known FODMAP triggers were detected."
        } else {
            prompt += " Detected triggers: \(flags)."
        }
        prompt += " Explain this verdict briefly."

        let response = try await explainSession.respond(to: prompt)
        return response.content
    }

    // MARK: - Ruleset suggestions from research data

    private let researchSession = LanguageModelSession(instructions: """
        You are a FODMAP diet researcher helping to improve an ingredient database for a low-FODMAP app. \
        Analyze the provided research data and suggest new ruleset entries using Monash University FODMAP data as reference. \
        Only suggest entries you are reasonably confident about. \
        Status must be exactly "safe", "caution", or "avoid". \
        Use these categories only: fructan, gos, lactose, excess_fructose, polyol, hidden_source, \
        safe_vegetable, safe_grain, safe_fat, safe_protein, safe_additive, safe_sweetener.
        """)

    func suggestEntries(
        unknowns: [UnknownIngredient],
        feedback: [VerdictFeedback]
    ) async throws -> [RulesetSuggestion] {
        var parts: [String] = []

        if !unknowns.isEmpty {
            let unique = Array(Set(unknowns.map(\.token))).sorted()
            parts.append("Unrecognized ingredients from user scans:\n" + unique.map { "- \($0)" }.joined(separator: "\n"))
        }

        if !feedback.isEmpty {
            let lines = feedback.map {
                "- Engine said \($0.engineVerdict) for \($0.productName ?? "unknown product"). User note: \($0.userNote)"
            }
            parts.append("User accuracy feedback:\n" + lines.joined(separator: "\n"))
        }

        guard !parts.isEmpty else { return [] }

        let prompt = parts.joined(separator: "\n\n")
            + "\n\nSuggest FODMAP ruleset entries for these ingredients. For accuracy feedback, suggest corrections where warranted."

        let response = try await researchSession.respond(to: prompt, generating: RulesetSuggestions.self)
        return response.content.entries
    }
}

// MARK: - Generable types for structured output

@available(iOS 26, *)
@Generable
struct RulesetSuggestion {
    @Guide(description: "Canonical ingredient name, lowercase singular, e.g. 'garlic' or 'avocado'")
    var name: String

    @Guide(description: "Common aliases, plural forms, and product variants")
    var aliases: [String]

    @Guide(description: "FODMAP safety level — must be exactly: safe, caution, or avoid")
    var status: String

    @Guide(description: "FODMAP category — must be one of: fructan, gos, lactose, excess_fructose, polyol, hidden_source, safe_vegetable, safe_grain, safe_fat, safe_protein, safe_additive, safe_sweetener")
    var category: String

    @Guide(description: "Brief clinical note about dose, nuance, or rationale. Empty string if none.")
    var notes: String
}

@available(iOS 26, *)
@Generable
struct RulesetSuggestions {
    @Guide(description: "Suggested new FODMAP ruleset entries based on the research data")
    var entries: [RulesetSuggestion]
}
