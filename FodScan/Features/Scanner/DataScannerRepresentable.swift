import SwiftUI
import VisionKit

struct DataScannerRepresentable: UIViewControllerRepresentable {
    let mode: ScanMode
    @Binding var scannedBarcode: String?
    @Binding var detectedText: String?

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let types: Set<DataScannerViewController.RecognizedDataType>
        switch mode {
        case .barcode:
            types = [.barcode()]
        case .ingredients, .lookup:
            types = [.text(textContentType: nil)]
        }

        let scanner = DataScannerViewController(
            recognizedDataTypes: types,
            qualityLevel: mode == .ingredients ? .accurate : .fast,
            recognizesMultipleItems: mode == .ingredients,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        context.coordinator.barcode = $scannedBarcode
        context.coordinator.text = $detectedText
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(mode: mode, barcode: $scannedBarcode, text: $detectedText)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let mode: ScanMode
        var barcode: Binding<String?>
        var text: Binding<String?>

        init(mode: ScanMode, barcode: Binding<String?>, text: Binding<String?>) {
            self.mode = mode
            self.barcode = barcode
            self.text = text
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            handle(allItems: allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            handle(allItems: allItems)
        }

        private func handle(allItems: [RecognizedItem]) {
            switch mode {
            case .barcode:
                for item in allItems {
                    if case .barcode(let b) = item, let payload = b.payloadStringValue {
                        barcode.wrappedValue = payload
                        return
                    }
                }
            case .ingredients, .lookup:
                // Sort text blocks top-to-bottom so the ingredient string reads naturally
                let lines = allItems
                    .compactMap { item -> (CGFloat, String)? in
                        guard case .text(let t) = item else { return nil }
                        return (t.bounds.topLeft.y, t.transcript)
                    }
                    .sorted { $0.0 < $1.0 }
                    .map(\.1)
                let joined = lines.joined(separator: ", ")
                text.wrappedValue = joined.isEmpty ? nil : joined
            }
        }
    }
}
