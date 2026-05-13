import Foundation

struct OFFProduct: Codable {
    let productName: String?
    let brands: String?
    let ingredientsText: String?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case ingredientsText = "ingredients_text"
        case imageUrl = "image_url"
    }
}

struct OFFResponse: Codable {
    let product: OFFProduct?
    let status: Int
}
