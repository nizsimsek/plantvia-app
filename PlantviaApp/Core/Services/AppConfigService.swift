//
//  AppConfigService.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 29.05.2026.
//

import Foundation

protocol AppConfigServiceProtocol {
    func fetchAppConfig() async throws -> AppConfig
}

final class AppConfigService: AppConfigServiceProtocol {
    func fetchAppConfig() async throws -> AppConfig {
        let envelope: APIEnvelope<AppConfig> = try await APIClient.shared.request("app/config?platform=ios")
        guard let config = envelope.data else { throw APIError.server(envelope.message) }
        return config
    }
}

struct AppConfig: Decodable {
    let platform: String
    let latestVersion: String
    let minimumSupportedVersion: String
    let forceUpdate: Bool
    let message: String
    let appStoreUrl: String
}
