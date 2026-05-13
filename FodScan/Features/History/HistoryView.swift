import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \ScanRecord.date, order: .reverse) private var records: [ScanRecord]
    @Environment(\.modelContext) private var modelContext
    @State private var showingClearConfirm = false

    var body: some View {
        List {
            ForEach(records) { record in
                NavigationLink {
                    ScanDetailView(record: record)
                } label: {
                    ScanHistoryRow(record: record)
                }
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear All", role: .destructive) {
                        showingClearConfirm = true
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
        }
        .confirmationDialog(
            "Delete all \(records.count) scan\(records.count == 1 ? "" : "s")?",
            isPresented: $showingClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                records.forEach { modelContext.delete($0) }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(records[index])
        }
    }
}

// MARK: - Detail view

private struct ScanDetailView: View {
    let record: ScanRecord

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: record.verdictStatus.iconName)
                        .foregroundStyle(record.verdictStatus.color)
                    Text(record.verdictStatus.label)
                        .foregroundStyle(record.verdictStatus.color)
                        .fontWeight(.semibold)
                }
                if let barcode = record.barcode {
                    LabeledContent("Barcode", value: barcode)
                }
                LabeledContent("Date", value: record.date.formatted(date: .long, time: .shortened))
            }

            if !record.flaggedIngredients.isEmpty {
                Section("Flagged") {
                    ForEach(record.flaggedIngredients, id: \.self) { name in
                        Text(name.capitalized)
                            .font(.subheadline)
                    }
                }
            }

            if let text = record.ingredientsText, !text.isEmpty {
                Section("All Ingredients") {
                    Text(text)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(record.productName ?? "Manual Scan")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Row

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
