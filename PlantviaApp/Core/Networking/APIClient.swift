//
//  APIClient.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation

final class APIClient {
    static let shared = APIClient()
    private init() {}

    static var onTokenRefreshNeeded: (() async throws -> String)?

    var baseURL = AppEnvironment.shared.apiBaseURL
    
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil, token: String? = nil) async throws -> T {
        print("BASEURL: ", baseURL)
        let url = try makeURL(endpoint)
        var urlRequest = URLRequest(url: url)
        configureNoCacheHeaders(&urlRequest)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            urlRequest.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        if let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode {
            return try JSONDecoder.plantvia.decode(T.self, from: data)
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode

        // ARCH-003: Silent refresh on 401 — skip for auth endpoints to prevent loops
        if statusCode == 401, token != nil, !endpoint.hasPrefix("auth/"),
           let refreshHandler = Self.onTokenRefreshNeeded,
           let newToken = try? await refreshHandler() {
            var retryRequest = urlRequest
            retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
            if let retryHTTP = retryResponse as? HTTPURLResponse, 200..<300 ~= retryHTTP.statusCode {
                return try JSONDecoder.plantvia.decode(T.self, from: retryData)
            }
        }

        let errorEnvelope = try? JSONDecoder.plantvia.decode(APIErrorEnvelope.self, from: data)
        Self.publishSessionExpiredIfNeeded(statusCode: statusCode, token: token)
        throw APIError.server(Self.userFriendlyErrorMessage(statusCode: statusCode, serverMessage: errorEnvelope?.message, token: token))
    }

    func uploadImage<T: Decodable>(_ endpoint: String, imageData: Data, fileName: String = "plant.jpg", token: String? = nil) async throws -> T {
        try await uploadMultipartImage(endpoint, imageData: imageData, fields: [:], fileName: fileName, token: token, fallbackMessage: "Photo could not be uploaded.".localized)
    }
    
    func uploadMultipartImage<T: Decodable>(_ endpoint: String, imageData: Data, fields: [String: String], fileName: String = "plant.jpg", token: String? = nil, fallbackMessage: String? = nil) async throws -> T {
        let boundary = "Boundary-\(UUID().uuidString)"
        let url = try makeURL(endpoint)
        var request = URLRequest(url: url)
        configureNoCacheHeaders(&request)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        for (name, value) in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.append(value)
            body.append("\r\n")
        }
        
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n")
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode {
            return try JSONDecoder.plantvia.decode(T.self, from: data)
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode

        // ARCH-003: Silent refresh on 401
        if statusCode == 401, token != nil, !endpoint.hasPrefix("auth/"),
           let refreshHandler = Self.onTokenRefreshNeeded,
           let newToken = try? await refreshHandler() {
            var retryRequest = request
            retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
            if let retryHTTP = retryResponse as? HTTPURLResponse, 200..<300 ~= retryHTTP.statusCode {
                return try JSONDecoder.plantvia.decode(T.self, from: retryData)
            }
        }

        let errorEnvelope = try? JSONDecoder.plantvia.decode(APIErrorEnvelope.self, from: data)
        Self.publishSessionExpiredIfNeeded(statusCode: statusCode, token: token)
        throw APIError.server(Self.userFriendlyErrorMessage(statusCode: statusCode, serverMessage: errorEnvelope?.message, token: token, fallback: fallbackMessage ?? "Photo could not be uploaded.".localized))
    }
    
    func imageURL(forPath path: String?) -> URL? {
        guard let path, !path.isEmpty,
              let scheme = baseURL.scheme,
              let host = baseURL.host else { return nil }
        let portPart = baseURL.port.map { ":\($0)" } ?? ""
        return URL(string: "\(scheme)://\(host)\(portPart)\(path)")
    }

    private func makeURL(_ endpoint: String) throws -> URL {
        let base = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let path = endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let urlString = "\(base)/\(path)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL(urlString)
        }
        return url
    }
    
    private func configureNoCacheHeaders(_ request: inout URLRequest) {
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
    }
    
    private static func publishSessionExpiredIfNeeded(statusCode: Int?, token: String?) {
        guard statusCode == 401, token != nil else { return }
        NotificationCenter.default.post(name: .sessionExpired, object: nil)
    }
    
    private static func userFriendlyErrorMessage(statusCode: Int?, serverMessage: String?, token: String?, fallback: String = "The expected response was not received from the server.".localized) -> String {
        guard let statusCode else { return fallback }
        
        switch statusCode {
            case 400, 422:
                return serverMessage?.localized ?? "Please check the fields and try again.".localized
            case 401:
                if token == nil {
                    return serverMessage?.localized ?? "Email or password is incorrect.".localized
                }
                return "Your session has expired. Please log in again.".localized
            case 403:
                return serverMessage?.localized ?? "You do not have permission for this action.".localized
            case 404:
                return "The requested record could not be found.".localized
            case 500...599:
                return "Something went wrong. Please try again later.".localized
            default:
                return serverMessage?.localized ?? fallback
        }
    }
}

extension Notification.Name {
    static let sessionExpired = Notification.Name("sessionExpired")
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}

extension JSONDecoder {
    static let plantvia: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = ISO8601DateFormatter.plantvia.date(from: value) {
                return date
            }
            if let date = ISO8601DateFormatter.plantviaNoFraction.date(from: value) {
                return date
            }
            if let date = DateFormatter.mysql.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date format is not supported: \(value)")
        }
        return decoder
    }()
}

extension ISO8601DateFormatter {
    static let plantvia: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    static let plantviaNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

extension DateFormatter {
    static let mysql: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void
    
    init(_ wrapped: Encodable) {
        encodeClosure = wrapped.encode
    }
    
    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

enum APIError: LocalizedError {
    case server(String)
    case invalidURL(String)

    var errorDescription: String? {
        switch self {
            case .server(let message): return message
            case .invalidURL(let url): return "Invalid URL: \(url)"
        }
    }
}

struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let message: String
    let data: T?
}

struct APIErrorEnvelope: Decodable {
    let success: Bool
    let message: String
}

struct EmptyAPIData: Decodable {}
