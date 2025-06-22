//
//  Product.swift
//  EndDemoRNR
//
//  Created by Robert Redmond on 19/06/2025.
//

import Foundation

struct Product: Codable, Identifiable, Equatable, Hashable {
    let endId: String // From JSON - might not be unique
    let id: String // Always unique for SwiftUI
    let name: String
    let price: String
    let image: String

    init(name: String, price: String, image: String, id: String) {
        self.endId = id
        self.id = UUID().uuidString
        self.name = name
        self.price = price
        self.image = image
    }

    // Custom Codable to handle uniqueID generation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.endId = try container.decode(String.self, forKey: .endId)
        self.id = UUID().uuidString // Always generate new unique ID
        self.name = try container.decode(String.self, forKey: .name)
        self.price = try container.decode(String.self, forKey: .price)
        self.image = try container.decode(String.self, forKey: .image)
    }

    // Hash and equality based on uniqueID for SwiftUI
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Product, rhs: Product) -> Bool {
        return lhs.id == rhs.id
    }

    private enum CodingKeys: String, CodingKey {
        case endId = "id"
        case name
        case price
        case image
    }
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
