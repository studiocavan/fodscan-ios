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

    private let session = LanguageModelSession(instructions: """
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
        if let name = productName, !name.isEmpty {
            prompt += " Product: \(name)."
        }
        if let raw = rawIngredientsText, !raw.isEmpty {
            prompt += " Full ingredient list: \(raw)."
        }
        if flags.isEmpty {
            prompt += " No known FODMAP triggers were detected."
        } else {
            prompt += " Detected triggers: \(flags)."
        }
        prompt += " Explain this verdict briefly."

        let response = try await session.respond(to: prompt)
        return response.content
    }
}
