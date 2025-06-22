//
//  ListViewModel.swift
//  EndDemoRNR
//
//  Created by Robert Redmond on 20/06/2025.
//

import Combine
import Foundation

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)

    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }

    var hasError: Bool {
        switch self {
        case .error:
            return true
        default:
            return false
        }
    }

    var errorMessage: String? {
        switch self {
        case .error(let message):
            return message
        default:
            return nil
        }
    }
}


// MARK: - List View Model
@MainActor
final class ListViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var state: LoadingState = .idle
    @Published var title: String = ""

    private let listService: ListServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(listService: ListServiceProtocol = ListService()) {
        self.listService = listService
    }

    func loadProducts() -> AnyPublisher<Void, Never> {
        guard !state.isLoading else {
            return Just(()).eraseToAnyPublisher()
        }

        state = .loading

        return Future<Void, Never> { [weak self] promise in
            Task { [weak self] in
                do {
                    let response = try await self?.listService.fetchProducts()
                    self?.title = response?.title ?? ""
                    self?.products = response?.products ?? []
                    self?.state = .loaded
                    promise(.success(()))

                } catch {
                    self?.state = .error(self?.getErrorMessage(for: error) ?? "Unknown error")
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func retryLoading() -> AnyPublisher<Void, Never> {
        return loadProducts()
    }

    func clearError() {
        if state.hasError {
            state = .idle
        }
    }

    private func getErrorMessage(for error: Error) -> String {
        if let requestError = error as? RequestError {
            switch requestError {
            case .serverError:
                return "Server temporarily unavailable. Please try again."
            case .networkError:
                return "Please check your internet connection."
            case .parsingError:
                return "Unable to process server response."
            }
        } else {
            return "An unexpected error occurred."
        }
    }
}
