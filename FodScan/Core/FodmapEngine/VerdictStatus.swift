import SwiftUI

enum VerdictStatus: String, Codable, Comparable {
    case safe
    case caution
    case avoid
    case unknown

    var label: String {
        switch self {
        case .safe:    "Safe"
        case .caution: "Caution"
        case .avoid:   "Avoid"
        case .unknown: "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .safe:    .green
        case .caution: .yellow
        case .avoid:   .red
        case .unknown: .gray
        }
    }

    private var severity: Int {
        switch self {
        case .safe:    0
        case .unknown: 1
        case .caution: 2
        case .avoid:   3
        }
    }

    static func < (lhs: VerdictStatus, rhs: VerdictStatus) -> Bool {
        lhs.severity < rhs.severity
    }
}
