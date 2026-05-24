import SwiftUI
import VisionKit

struct DataScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedBarcode: String?

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        context.coordinator.barcode = $scannedBarcode
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(barcode: $scannedBarcode) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var barcode: Binding<String?>

        init(barcode: Binding<String?>) { self.barcode = barcode }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            scan(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            scan(allItems)
        }

        private func scan(_ items: [RecognizedItem]) {
            for item in items {
                if case .barcode(let b) = item, let payload = b.payloadStringValue {
                    barcode.wrappedValue = payload
                    return
                }
            }
        }
    }
}
