import SwiftUI

@main
struct FodScanApp: App {
    // Instantiate at launch so the ruleset is parsed before the scanner opens
    private let container = AppContainer.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(container.scannerViewModel)
        }
        .modelContainer(.fodScan)
    }
}
