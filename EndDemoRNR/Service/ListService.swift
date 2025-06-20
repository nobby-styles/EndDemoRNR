//
//  ListService.swift
//  EndDemoRNR
//
//  Created by Robert Redmond on 19/06/2025.
//

import Foundation


// MARK: - List Service Protocol
protocol ListServiceProtocol {
    func fetchProducts() async throws -> ProductsResponse
}

// MARK: - List Service Implementation
final class ListService: ListServiceProtocol {
    private let httpRequest: HTTPRequestProtocol
    private let baseURL: String
    
    init(
        httpRequest: HTTPRequestProtocol = HTTPRequest(),
        baseURL: String = "https://www.endclothing.com/media/catalog/example.json"
    ) {
        self.httpRequest = httpRequest
        self.baseURL = baseURL
    }
    
    func fetchProducts() async throws -> ProductsResponse {
        guard let url = URL(string: baseURL) else {
            throw RequestError.networkError
        }
        
        return try await httpRequest.performRequest(
            url: url,
            type: ProductsResponse.self,
            timeout: 30.0
        )
    }
}
