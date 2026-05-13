import Foundation

actor OpenFoodFactsClient {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "FodScan/1.0 (com.studiocavan.fodscan)"
        ]
        session = URLSession(configuration: config)
    }

    func product(for barcode: String) async throws -> OFFProduct? {
        let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json")!
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(OFFResponse.self, from: data)
        guard response.status == 1 else { return nil }
        return response.product
    }
}
