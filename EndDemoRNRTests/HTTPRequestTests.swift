//
//  HTTPRequestTests.swift
//  EndDemoRNR
//
//  Created by Robert Redmond on 19/06/2025.
//

import XCTest
@testable import EndDemoRNR

// MARK: - HTTP Request Tests
final class HTTPRequestTests: XCTestCase {
    private var httpRequest: HTTPRequest!

    override func setUp() {
        super.setUp()
        httpRequest = HTTPRequest()
    }

    override func tearDown() {
        httpRequest = nil
        super.tearDown()
    }

    func testRealEndClothingAPIRequest() async throws {
        // Given
        let url = URL(string: "https://www.endclothing.com/media/catalog/example.json")!

        // When
        let result: ProductsResponse = try await httpRequest.performRequest(
            url: url,
            type: ProductsResponse.self,
            timeout: 30.0
        )

        // Then
        XCTAssertGreaterThan(result.products.count, 0, "Should have at least one product")
        XCTAssertEqual(result.title, "Exercise Listing")
        XCTAssertGreaterThan(result.productCount, 0, "Product count should be greater than 0")

        // Verify product structure
        let firstProduct = result.products.first!
        XCTAssertFalse(firstProduct.id.isEmpty, "Product ID should not be empty")
        XCTAssertFalse(firstProduct.name.isEmpty, "Product name should not be empty")
        XCTAssertFalse(firstProduct.price.isEmpty, "Product price should not be empty")
        XCTAssertFalse(firstProduct.image.isEmpty, "Product image should not be empty")
    }

    func testInvalidURLRequest() async {
        // Given
        let url = URL(string: "https://invalid-url-that-does-not-exist.com/api")!

        // When/Then
        do {
            let _: ProductsResponse = try await httpRequest.performRequest(
                url: url,
                type: ProductsResponse.self,
                timeout: 10.0
            )
            XCTFail("Should throw a network error")
        } catch RequestError.networkError {
            // Expected
        } catch RequestError.serverError {
            // Also acceptable for DNS resolution failures
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testMalformedJSONResponse() async {
        // Given - Using a URL that returns HTML instead of JSON
        let url = URL(string: "https://httpbin.org/html")!

        // When/Then
        do {
            let _: ProductsResponse = try await httpRequest.performRequest(
                url: url,
                type: ProductsResponse.self,
                timeout: 10.0
            )
            XCTFail("Should throw a parsing error")
        } catch RequestError.parsingError {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test404ServerError() async {
        // Given
        let url = URL(string: "https://httpbin.org/status/404")!

        // When/Then
        do {
            let _: ProductsResponse = try await httpRequest.performRequest(
                url: url,
                type: ProductsResponse.self,
                timeout: 10.0
            )
            XCTFail("Should throw a server error")
        } catch RequestError.serverError {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test500ServerError() async {
        // Given
        let url = URL(string: "https://httpbin.org/status/500")!

        // When/Then
        do {
            let _: ProductsResponse = try await httpRequest.performRequest(
                url: url,
                type: ProductsResponse.self,
                timeout: 10.0
            )
            XCTFail("Should throw a server error")
        } catch RequestError.serverError {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
