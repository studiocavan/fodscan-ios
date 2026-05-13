import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \ScanRecord.date, order: .reverse) private var records: [ScanRecord]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(records) { record in
                ScanHistoryRow(record: record)
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Scan History")
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if records.isEmpty {
                ContentUnavailableView(
                    "No scans yet",
                    systemImage: "barcode.viewfinder",
                    description: Text("Scan a product to see your history here.")
                )
            }
        }
        .toolbar {
            if !records.isEmpty {
                EditButton()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(records[index])
        }
    }
}

private struct ScanHistoryRow: View {
    let record: ScanRecord

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(record.verdictStatus.color.opacity(0.18))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: record.verdictStatus.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(record.verdictStatus.color)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(record.productName ?? "Manual scan")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                if record.flaggedIngredients.isEmpty {
                    Text("No triggers found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(record.flaggedIngredients.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(record.verdictStatus.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(record.verdictStatus.color)
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

private extension VerdictStatus {
    var iconName: String {
        switch self {
        case .safe:    "checkmark.circle.fill"
        case .caution: "exclamationmark.circle.fill"
        case .avoid:   "xmark.circle.fill"
        case .unknown: "questionmark.circle.fill"
        }
    }
}
