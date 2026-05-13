import Foundation

@MainActor
final class AppContainer {
    static let shared = AppContainer()
    let scannerViewModel = ScannerViewModel()
    private init() {}
}
