//
//  ProductDetailView.swift
//  EndDemoRNR
//
//  Created by Robert Redmond on 21/06/2025.
//


import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @ObservedObject var coordinator: ProductListCoordinator
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Product Image
                AsyncImage(url: URL(string: product.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            ProgressView()
                        }
                }
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Product Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(product.price)
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Spacer(minLength: 20)
                    
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Product Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
