//
//  HTTPRequest.swift
//  EndDemoRNR
//
//  Created by Robert Redmond on 19/06/2025.
//

import Foundation


enum RequestError: Error, Equatable, LocalizedError {
    case serverError
    case networkError
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .serverError:
            return "Server error occurred"
        case .networkError:
            return "Network connection error"
        case .parsingError:
            return "Data parsing error"
        }
    }
}

// MARK: - HTTP Request Protocol
protocol HTTPRequestProtocol {
    func performRequest<T: Codable>(
        url: URL,
        type: T.Type,
        timeout: TimeInterval
    ) async throws -> T
}

// MARK: - HTTP Request Implementation
final class HTTPRequest: HTTPRequestProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func performRequest<T: Codable>(
        url: URL,
        type: T.Type,
        timeout: TimeInterval = 30.0
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                throw RequestError.serverError
            }
            
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(type, from: data)
            } catch {
                throw RequestError.parsingError
            }
        } catch let error as RequestError {
            throw error
        } catch {
            throw RequestError.networkError
        }
    }
}
