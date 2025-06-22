//
//  Coordinator.swift
//  EndDemoRNR
//
//  Created by Robert Redmond on 21/06/2025.
//


import SwiftUI

@MainActor
protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    func start()
}

//
//  ProductListCoordinator.swift
//

import SwiftUI

@MainActor
final class ProductListCoordinator: ObservableObject, Coordinator {
    @Published var path = NavigationPath()
    var childCoordinators: [Coordinator] = []
    
    func start() {
        // Initial setup if needed
    }
    
    func showProductDetail(_ product: Product) {
        path.append(product)
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
}
