//
//  AppUpdateStore.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 29.05.2026.
//

import Foundation
import Combine

@MainActor
final class AppUpdateStore: ObservableObject {
    @Published private(set) var requiredUpdate: AppConfig?
    @Published private(set) var status: LoadingState = .idle
    
    private let appConfigService: AppConfigServiceProtocol
    
    init(appConfigService: AppConfigServiceProtocol) {
        self.appConfigService = appConfigService
    }
    
    func checkForRequiredUpdate(isOnline: Bool) async {
        guard isOnline else { return }
        
        status = .loading
        do {
            let config = try await appConfigService.fetchAppConfig()
            requiredUpdate = Self.isCurrentVersionSupported(minimumSupportedVersion: config.minimumSupportedVersion) ? nil : config
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }
    
    private static func isCurrentVersionSupported(minimumSupportedVersion: String) -> Bool {
        compareVersions(currentAppVersion, minimumSupportedVersion) != .orderedAscending
    }
    
    private static var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
    
    private static func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let leftParts = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let rightParts = rhs.split(separator: ".").map { Int($0) ?? 0 }
        let count = max(leftParts.count, rightParts.count)
        
        for index in 0..<count {
            let left = index < leftParts.count ? leftParts[index] : 0
            let right = index < rightParts.count ? rightParts[index] : 0
            
            if left < right { return .orderedAscending }
            if left > right { return .orderedDescending }
        }
        
        return .orderedSame
    }
}
