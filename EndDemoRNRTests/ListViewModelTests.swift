//
//  ListViewModelTests.swift
//  EndDemoRNR
//
//  Created by Robert Redmond on 20/06/2025.
//


// MARK: - ListViewModel Unit Tests
import XCTest
import Combine
@testable import EndDemoRNR

final class ListViewModelTests: XCTestCase {
    private var viewModel: ListViewModel!
    private var mockListService: MockListService!
    private var cancellables: Set<AnyCancellable>!

    @MainActor
    override func setUp() {
        super.setUp()
        mockListService = MockListService()
        viewModel = ListViewModel(listService: mockListService)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        viewModel = nil
        mockListService = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Success Tests
    @MainActor
    func testLoadProductsSuccess() async {
        // Given
        let expectedProducts = [
            Product(id: "1", name: "Test Shirt", price: "£199", image: "test.jpg"),
            Product(id: "2", name: "Test Shoes", price: "£299", image: "test2.jpg")
        ]
        let mockResponse = ProductsResponse(
            products: expectedProducts,
            title: "Test Products",
            productCount: 2
        )
        mockListService.mockResponse = mockResponse

        let stateExpectation = expectation(description: "State changes through loading cycle")
        var states: [LoadingState] = []

        viewModel.$state
            .sink { state in
                states.append(state)
                if states.count == 3 { // idle -> loading -> loaded
                    stateExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        let cancellable = viewModel.loadProducts()
            .sink { _ in }

        // Then
        await fulfillment(of: [stateExpectation], timeout: 1.0)

        XCTAssertEqual(viewModel.products.count, 2)
        XCTAssertEqual(viewModel.products.first?.name, "Test Shirt")
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertFalse(viewModel.state.hasError)

        cancellable.cancel()
    }

    @MainActor
    func testLoadProductsEmptyResponse() async {
        // Given
        let mockResponse = ProductsResponse(
            products: [],
            title: "Empty Products",
            productCount: 0
        )
        mockListService.mockResponse = mockResponse

        let completionExpectation = expectation(description: "Load completes")

        // When
        let cancellable = viewModel.loadProducts()
            .sink { _ in
                completionExpectation.fulfill()
            }

        // Then
        await fulfillment(of: [completionExpectation], timeout: 1.0)

        XCTAssertTrue(viewModel.products.isEmpty)
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertFalse(viewModel.state.hasError)

        cancellable.cancel()
    }

    // MARK: - Error Tests
    @MainActor
    func testLoadProductsServerError() async {
        // Given
        mockListService.mockError = RequestError.serverError

        let errorExpectation = expectation(description: "Error state changes")

        viewModel.$state
            .filter { $0.hasError }
            .sink { _ in
                errorExpectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        let cancellable = viewModel.loadProducts()
            .sink { _ in }

        // Then
        await fulfillment(of: [errorExpectation], timeout: 1.0)

        XCTAssertTrue(viewModel.products.isEmpty)
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertTrue(viewModel.state.hasError)
        XCTAssertEqual(viewModel.state.errorMessage, "Server temporarily unavailable. Please try again.")

        cancellable.cancel()
    }

    @MainActor
    func testLoadProductsNetworkError() async {
        // Given
        mockListService.mockError = RequestError.networkError

        let errorExpectation = expectation(description: "Error state reached")

        // When
        let cancellable = viewModel.loadProducts()
            .sink { _ in
                errorExpectation.fulfill()
            }

        // Then
        await fulfillment(of: [errorExpectation], timeout: 1.0)

        XCTAssertTrue(viewModel.state.hasError)
        XCTAssertEqual(viewModel.state.errorMessage, "Please check your internet connection.")

        cancellable.cancel()
    }

    @MainActor
    func testLoadProductsParsingError() async {
        // Given
        mockListService.mockError = RequestError.parsingError

        let errorExpectation = expectation(description: "Parsing error state reached")

        // When
        let cancellable = viewModel.loadProducts()
            .sink { _ in
                errorExpectation.fulfill()
            }

        // Then
        await fulfillment(of: [errorExpectation], timeout: 1.0)

        XCTAssertTrue(viewModel.state.hasError)
        XCTAssertEqual(viewModel.state.errorMessage, "Unable to process server response.")

        cancellable.cancel()
    }

    // MARK: - Behavior Tests
    @MainActor
    func testRetryLoading() async {
        // Given
        mockListService.mockError = RequestError.networkError

        let firstErrorExpectation = expectation(description: "First load fails")
        let cancellable1 = viewModel.loadProducts()
            .sink { _ in
                firstErrorExpectation.fulfill()
            }

        await fulfillment(of: [firstErrorExpectation], timeout: 1.0)
        XCTAssertTrue(viewModel.state.hasError)

        // When - Setup success response and retry
        let successProducts = [Product(id: "1", name: "Retry Test", price: "£99", image: "retry.jpg")]
        mockListService.mockResponse = ProductsResponse(products: successProducts, title: "Retry", productCount: 1)
        mockListService.mockError = nil

        let retryExpectation = expectation(description: "Retry succeeds")
        let cancellable2 = viewModel.retryLoading()
            .sink { _ in
                retryExpectation.fulfill()
            }

        await fulfillment(of: [retryExpectation], timeout: 1.0)

        // Then
        XCTAssertEqual(viewModel.products.count, 1)
        XCTAssertEqual(viewModel.products.first?.name, "Retry Test")
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertFalse(viewModel.state.hasError)

        cancellable1.cancel()
        cancellable2.cancel()
    }

    @MainActor
    func testClearError() async {
        // Given
        mockListService.mockError = RequestError.serverError

        let errorExpectation = expectation(description: "Error state reached")
        let cancellable = viewModel.loadProducts()
            .sink { _ in
                errorExpectation.fulfill()
            }

        await fulfillment(of: [errorExpectation], timeout: 1.0)
        XCTAssertTrue(viewModel.state.hasError)

        // When
        viewModel.clearError()

        // Then
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertFalse(viewModel.state.hasError)
        XCTAssertNil(viewModel.state.errorMessage)

        cancellable.cancel()
    }

    @MainActor
    func testPreventDuplicateLoading() async {
        // Given
        mockListService.shouldDelay = true // Simulate slow response

        // When - Call loadProducts twice quickly
        let firstExpectation = expectation(description: "First load completes")
        let cancellable1 = viewModel.loadProducts()
            .sink { _ in
                firstExpectation.fulfill()
            }

        // Second call should be ignored due to guard
        let cancellable2 = viewModel.loadProducts()
            .sink { _ in }

        await fulfillment(of: [firstExpectation], timeout: 2.0)

        // Then
        XCTAssertEqual(mockListService.fetchProductsCallCount, 1, "Should only call service once")

        cancellable1.cancel()
        cancellable2.cancel()
    }

    // MARK: - State Tests
    @MainActor
    func testStateTransitions() async {
        // Test all state transitions
        XCTAssertEqual(viewModel.state, .idle)

        // Start loading
        mockListService.shouldDelay = true
        let cancellable = viewModel.loadProducts()
            .sink { _ in }

        // Should be loading
        XCTAssertEqual(viewModel.state, .loading)
        XCTAssertTrue(viewModel.state.isLoading)

        // Wait for completion
        let completionExpectation = expectation(description: "Loading completes")
        viewModel.$state
            .filter { $0 == .loaded }
            .sink { _ in
                completionExpectation.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [completionExpectation], timeout: 2.0)

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertFalse(viewModel.state.isLoading)

        cancellable.cancel()
    }
}

// MARK: - Mock List Service for Testing
final class MockListService: ListServiceProtocol {
    var mockResponse: ProductsResponse?
    var mockError: RequestError?
    var shouldDelay = false
    var fetchProductsCallCount = 0

    func fetchProducts() async throws -> ProductsResponse {
        fetchProductsCallCount += 1

        if shouldDelay {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        if let error = mockError {
            throw error
        }

        return mockResponse ?? ProductsResponse(products: [], title: "Default", productCount: 0)
    }
}
