import SwiftUI

struct IngredientBreakdownView: View {
    let matches: [IngredientMatch]

    var body: some View {
        List(matches, id: \.token) { match in
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(match.entry.status.color)
                    .frame(width: 10, height: 10)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 3) {
                    Text(match.entry.name.capitalized)
                        .font(.body.weight(.medium))
                    Text(match.entry.category.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let notes = match.entry.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(match.entry.status.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(match.entry.status.color)
            }
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
    }
}
