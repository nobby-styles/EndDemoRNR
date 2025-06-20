//
//  Product.swift
//  EndDemoRNR
//
//  Created by Robert Redmond on 19/06/2025.
//


struct Product: Codable {
    let id: String
    let name: String
    let price: String
    let image: String

}

struct ProductsResponse: Codable {
    let products: [Product]
    let title: String
    let productCount: Int
    
    enum CodingKeys: String, CodingKey {
        case products
        case title
        case productCount = "product_count"
    }
}
