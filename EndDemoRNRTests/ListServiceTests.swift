//
//  ListServiceTests.swift
//  EndDemoRNR
//
//  Created by Robert Redmond on 19/06/2025.
//

import XCTest
@testable import EndDemoRNR


final class ListServiceTests: XCTestCase {
    private var listService: ListService!
    private var mockHTTPRequest: MockHTTPRequest!
    
    override func setUp() {
        super.setUp()
        mockHTTPRequest = MockHTTPRequest()
        listService = ListService(httpRequest: mockHTTPRequest)
    }
    
    override func tearDown() {
        listService = nil
        mockHTTPRequest = nil
        super.tearDown()
    }
    
    // MARK: - Success Tests
    func testFetchProductsSuccess() async throws {
        // Given
        let expectedProducts = [
            Product(
                id: "1",
                name: "Test Shirt",
                price: "£199",
                image: "https://example.com/image.jpg"
            )
        ]
        
        let expectedResponse = ProductsResponse(
            products: expectedProducts,
            title: "Test Products",
            productCount: 1
        )
        
        let jsonData = try JSONEncoder().encode(expectedResponse)
        mockHTTPRequest.mockData = jsonData
        
        // When
        let response = try await listService.fetchProducts()
        
        // Then
        XCTAssertEqual(response.products.count, 1)
        XCTAssertEqual(response.products.first?.id, "1")
        XCTAssertEqual(response.products.first?.name, "Test Shirt")
        XCTAssertEqual(response.products.first?.price, "£199")
        XCTAssertEqual(response.title, "Test Products")
        XCTAssertEqual(response.productCount, 1)
    }
    
    func testFetchProductsEmptyArray() async throws {
        // Given
        let expectedResponse = ProductsResponse(
            products: [],
            title: "Empty Products",
            productCount: 0
        )
        let jsonData = try JSONEncoder().encode(expectedResponse)
        mockHTTPRequest.mockData = jsonData
        
        // When
        let response = try await listService.fetchProducts()
        
        // Then
        XCTAssertTrue(response.products.isEmpty)
        XCTAssertEqual(response.productCount, 0)
    }
    
    // MARK: - Error Tests
    func testFetchProductsInvalidURL() async {
        // Given
        
        let invalidService = ListService(
            httpRequest: mockHTTPRequest,
            baseURL: ""
        )
        
        // When/Then
        do {
            _ = try await invalidService.fetchProducts()
            XCTFail("Should throw RequestError.networkError")
        } catch RequestError.networkError {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testFetchProductsServerError() async {
        // Given
        mockHTTPRequest.mockError = RequestError.serverError
        
        // When/Then
        do {
            _ = try await listService.fetchProducts()
            XCTFail("Should throw RequestError.serverError")
        } catch RequestError.serverError {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testFetchProductsRequestError() async {
        // Given
        mockHTTPRequest.mockError = RequestError.networkError
        
        // When/Then
        do {
            _ = try await listService.fetchProducts()
            XCTFail("Should throw RequestError.networkError")
        } catch RequestError.networkError {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testFetchProductsDecodingError() async {
        // Given
        let invalidJSON = "{ invalid json }".data(using: .utf8)!
        mockHTTPRequest.mockData = invalidJSON
        
        // When/Then
        do {
            _ = try await listService.fetchProducts()
            XCTFail("Should throw RequestError.serverError")
        } catch RequestError.parsingError {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

final class MockHTTPRequest: HTTPRequestProtocol {
    var mockData: Data?
    var mockError: RequestError?

    func performRequest<T: Codable>(
        url: URL,
        type: T.Type,
        timeout: TimeInterval
    ) async throws -> T {
        if let error = mockError {
            throw error
        }

        guard let data = mockData else {
            throw RequestError.serverError
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            throw RequestError.parsingError
        }
    }
}

