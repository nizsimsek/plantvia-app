//
//  AppContainer.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation
import Combine

@MainActor
final class AppContainer: ObservableObject {
    let authService: AuthServiceProtocol
    let plantService: PlantServiceProtocol
    let aiService: AIAnalysisServiceProtocol
    let revenueCatService: RevenueCatServiceProtocol
    let adsService: AdsServiceProtocol
    let notificationService: NotificationServiceProtocol
    let appConfigService: AppConfigServiceProtocol
    
    init(
        authService: AuthServiceProtocol? = nil,
        plantService: PlantServiceProtocol? = nil,
        aiService: AIAnalysisServiceProtocol? = nil,
        revenueCatService: RevenueCatServiceProtocol? = nil,
        adsService: AdsServiceProtocol? = nil,
        notificationService: NotificationServiceProtocol? = nil,
        appConfigService: AppConfigServiceProtocol? = nil
    ) {
        self.authService = authService ?? AuthService()
        self.plantService = plantService ?? PlantService()
        self.aiService = aiService ?? AIAnalysisService()
        self.revenueCatService = revenueCatService ?? RevenueCatService()
        self.adsService = adsService ?? AdsService()
        self.notificationService = notificationService ?? NotificationService()
        self.appConfigService = appConfigService ?? AppConfigService()
    }
}
