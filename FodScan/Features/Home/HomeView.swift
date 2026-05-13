import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    NavigationLink { ScannerView() } label: {
                        HomeTile(icon: "barcode.viewfinder", title: "Scan", accent: .green)
                    }
                    .buttonStyle(.plain)

                    NavigationLink { HistoryView() } label: {
                        HomeTile(icon: "clock.arrow.circlepath", title: "Scan History", accent: .blue)
                    }
                    .buttonStyle(.plain)

                    NavigationLink { ExploreSafeFoodsView() } label: {
                        HomeTile(icon: "leaf.fill", title: "Explore Foods", accent: .mint)
                    }
                    .buttonStyle(.plain)

                    NavigationLink { MealPrepView() } label: {
                        HomeTile(icon: "fork.knife", title: "Meal Prep", accent: .orange)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("FodScan")
        }
    }
}

private struct HomeTile: View {
    let icon: String
    let title: String
    let accent: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(accent)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 130)
        .padding(8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
