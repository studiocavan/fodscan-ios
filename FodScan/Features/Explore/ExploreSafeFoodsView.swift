import SwiftUI

struct ExploreSafeFoodsView: View {
    @State private var entries: [FodmapEntry] = []
    @State private var searchText = ""
    @AppStorage("exploreFilterStatus") private var filterRawValue: String = VerdictStatus.safe.rawValue
    @State private var sortBySeverity = false

    private var filterStatus: VerdictStatus? {
        get { filterRawValue == "all" ? nil : VerdictStatus(rawValue: filterRawValue) }
    }

    private func setFilter(_ status: VerdictStatus?) {
        filterRawValue = status?.rawValue ?? "all"
    }

    private var displayed: [FodmapEntry] {
        var result = entries
        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.aliases.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        if sortBySeverity {
            result.sort { $0.status > $1.status }
        } else {
            result.sort { $0.name < $1.name }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            List(displayed, id: \.name) { entry in
                FodmapEntryRow(entry: entry)
            }
            .listStyle(.plain)
            .overlay {
                if displayed.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView("No Entries", systemImage: "questionmark.circle")
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search ingredients")
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        sortBySeverity = false
                    } label: {
                        Label("A – Z", systemImage: sortBySeverity ? "" : "checkmark")
                    }
                    Button {
                        sortBySeverity = true
                    } label: {
                        Label("By severity", systemImage: sortBySeverity ? "checkmark" : "")
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
        }
        .onAppear {
            if entries.isEmpty {
                entries = (try? RulesetLoader.load())?.entries ?? []
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                StatusChip(label: "All", color: .primary, isSelected: filterStatus == nil) {
                    setFilter(nil)
                }
                StatusChip(label: "Avoid", color: .red, isSelected: filterStatus == .avoid) {
                    setFilter(filterStatus == .avoid ? nil : .avoid)
                }
                StatusChip(label: "Caution", color: .orange, isSelected: filterStatus == .caution) {
                    setFilter(filterStatus == .caution ? nil : .caution)
                }
                StatusChip(label: "Safe", color: .green, isSelected: filterStatus == .safe) {
                    setFilter(filterStatus == .safe ? nil : .safe)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
    }
}

private struct StatusChip: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color.opacity(0.15) : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? color : .primary)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(isSelected ? color : Color.clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

private struct FodmapEntryRow: View {
    let entry: FodmapEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(entry.status.color)
                    .frame(width: 9, height: 9)
                Text(entry.name.capitalized)
                    .font(.body.weight(.medium))
                Spacer()
                Text(entry.status.label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(entry.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(entry.status.color.opacity(0.12))
                    .clipShape(Capsule())
            }
            Text(entry.category.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let notes = entry.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }
}
