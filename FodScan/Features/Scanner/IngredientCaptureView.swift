import SwiftUI
import UIKit
import Vision

struct IngredientCaptureView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        let onCancel: () -> Void

        init(onCapture: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let image = info[.originalImage] as? UIImage else { onCancel(); return }
            onCapture(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}

// MARK: - Vision OCR

func recognizeIngredientText(in image: UIImage) async -> String {
    guard let cgImage = image.cgImage else { return "" }
    return await withCheckedContinuation { continuation in
        let request = VNRecognizeTextRequest { request, _ in
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            // Vision origin is bottom-left; sort descending minY = top-to-bottom reading order
            let lines = observations
                .sorted { $0.boundingBox.minY > $1.boundingBox.minY }
                .compactMap { $0.topCandidates(1).first?.string }
            continuation.resume(returning: lines.joined(separator: " "))
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}

// MARK: - Allergen advisory stripping

struct StripResult {
    let text: String
    let allergenWarningsRemoved: Bool
}

func stripAllergenAdvisories(from text: String) -> StripResult {
    // These are cross-contamination/allergen declarations, not ingredient declarations.
    // FODMAP is dose-dependent — trace cross-contamination is not clinically relevant.
    let patterns = [
        "may contain",
        "allergy advice",
        "allergy information",
        "allergen information",
        "allergen advice",
        "processed in a facility",
        "manufactured in a facility",
        "made in a facility",
        "produced in a facility",
        "manufactured on shared equipment",
        "produced on shared equipment",
    ]
    let lower = text.lowercased()
    var cutIndex = text.endIndex
    for pattern in patterns {
        if let range = lower.range(of: pattern), range.lowerBound < cutIndex {
            cutIndex = range.lowerBound
        }
    }
    guard cutIndex < text.endIndex else { return StripResult(text: text, allergenWarningsRemoved: false) }
    let cleaned = String(text[..<cutIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
    return StripResult(text: cleaned.isEmpty ? text : cleaned, allergenWarningsRemoved: true)
}
