//
//  ProductListView.swift
//  EndDemoRNR
//
//  Created by Robert Redmond on 21/06/2025.
//

import Combine
import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ListViewModel()
    @ObservedObject var coordinator: ProductListCoordinator

    @State private var cancellables = Set<AnyCancellable>()

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.products) { product in
                    ProductCardView(product: product) {
                        coordinator.showProductDetail(product)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle(viewModel.title)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 0) {
                    BorderedButton(title: "Sort ▼") {
                        // Handle sort action
                    }

                    BorderedButton(title: "View ▼") {
                        // Handle view toggle
                    }

                    BorderedButton(title: "Filter") {
                        // Handle filter action
                    }

                }
                .frame(maxWidth: .infinity)
            }
        }
        .overlay {
            if viewModel.state.isLoading {
                LoadingView()
            } else if viewModel.state.hasError {
                ErrorView(
                    message: viewModel.state.errorMessage ?? "Unknown error",
                    onRetry: {
                        loadProducts()
                    }
                )
            }
        }

        .onAppear {
            loadProducts()
        }
        .refreshable {
            await withCheckedContinuation { continuation in
                viewModel.loadProducts()
                    .sink { _ in
                        continuation.resume()
                    }
                    .store(in: &cancellables)
            }
        }
    }

    private func loadProducts() {
        viewModel.loadProducts()
            .sink { _ in }
            .store(in: &cancellables)
    }
}

struct BorderedButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title) {
            action()
        }
        .foregroundColor(.black)
        .frame(maxWidth: .infinity)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ProductCardView: View {
    let product: Product
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                AsyncImage(url: URL(string: product.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fill)
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .center, spacing: 4) {
                Text(product.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(.black)

                Text(product.price)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

            }
            .frame(maxWidth: .infinity)
        }
    }
}
