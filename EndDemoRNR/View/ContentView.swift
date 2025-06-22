//
//  ContentView.swift
//  EndDemoRNR
//
//  Created by Robert Redmond on 19/06/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator = ProductListCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ProductListView(coordinator: coordinator)
                .navigationDestination(for: Product.self) { product in
                    ProductDetailView(product: product, coordinator: coordinator)
                }
        }
        .onAppear {
            coordinator.start()
        }
    }
}
