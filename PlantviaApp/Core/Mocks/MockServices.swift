//
//  MockServices.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation
import UserNotifications

final class MockAuthService: AuthServiceProtocol {
    func login(email: String, password: String) async throws -> AuthSession {
        AuthSession(user: User(id: 1, nickname: "Preview", email: email, plan: "premium", language: "tr"), accessToken: "preview-token", refreshToken: "preview-refresh")
    }

    func register(nickname: String, email: String, password: String) async throws -> AuthSession {
        AuthSession(user: User(id: 1, nickname: nickname, email: email, plan: "free", language: "tr"), accessToken: "preview-token", refreshToken: "preview-refresh")
    }
    
    func refresh(refreshToken: String) async throws -> AuthSession {
        AuthSession(user: User(id: 1, nickname: "Preview", email: "preview@plantvia.app", plan: "premium", language: "tr"), accessToken: "preview-token", refreshToken: "preview-refresh")
    }
    func forgotPassword(email: String) async throws {}
    func resetPassword(token: String, password: String) async throws {}
    func updateProfile(nickname: String, token: String) async throws -> User {
        User(id: 1, nickname: nickname, email: "preview@plantvia.app", plan: "premium", language: "tr")
    }
    func updateSettings(language: String, token: String) async throws -> User {
        User(id: 1, nickname: "Preview", email: "preview@plantvia.app", plan: "premium", language: language)
    }
    func logout(refreshToken: String) async throws {}
}

final class MockAIAnalysisService: AIAnalysisServiceProtocol {
    func performPlantAnalysis(question: String, plantId: Int?, imageData: Data?, token: String?) async throws -> AIAnalysisAnswer {
        AIAnalysisAnswer(
            answer: "Mock AI answer: The plant looks generally healthy; check the top layer of soil before watering.",
            suggestions: ["Check soil moisture", "Use bright indirect light"],
            confidenceLevel: "Medium",
            warning: "This answer is for testing only.",
            remaining: 47
        )
    }

    func fetchAiStatus(token: String?) async throws -> AIUsageStatus {
        AIUsageStatus(used: 3, remaining: 47, limit: 50)
    }
}

final class MockPlantService: PlantServiceProtocol {
    func fetchPlants(token: String) async throws -> [Plant] { Self.previewPlants }
    func createPlant(_ request: PlantMutationRequest, token: String) async throws -> Plant {
        Plant(id: 99, name: request.name, species: request.species, imageUrl: request.imageUrl, location: PlantLocation(rawValue: request.location) ?? .salon, wateringFrequencyDays: request.wateringFrequencyDays, reminderTime: request.reminderTime, lastWateredAt: Date(), notes: request.notes)
    }
    func updatePlant(plantId: Int, _ request: PlantMutationRequest, token: String) async throws -> Plant {
        Plant(id: plantId, name: request.name, species: request.species, imageUrl: request.imageUrl, location: PlantLocation(rawValue: request.location) ?? .salon, wateringFrequencyDays: request.wateringFrequencyDays, reminderTime: request.reminderTime, lastWateredAt: Date(), notes: request.notes)
    }
    func deletePlant(plantId: Int, token: String) async throws {}
    func waterPlant(plantId: Int, wateredAt: Date, note: String, token: String) async throws -> WateringLog {
        WateringLog(id: 1, wateredAt: wateredAt, note: note)
    }
    func fetchWateringHistory(plantId: Int, token: String) async throws -> [WateringLog] { [] }
    func uploadPhoto(_ imageData: Data, token: String) async throws -> UploadedFile {
        UploadedFile(filename: "preview.jpg", originalName: "preview.jpg", size: imageData.count, url: "/uploads/preview.jpg")
    }
    
    private static let previewPlants: [Plant] = [
        Plant(id: 1, name: "Monstera", species: "Monstera Deliciosa", imageName: "leaf.fill", imageUrl: nil, location: .salon, wateringFrequencyDays: 5, lastWateredAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, notes: "Loves bright indirect light.", wateringHistory: [WateringLog(wateredAt: Date(), note: "Soil was moist, watered lightly.")]),
        Plant(id: 2, name: "Snake Plant", species: "Sansevieria", imageName: "camera.macro", imageUrl: nil, location: .bedRoom, wateringFrequencyDays: 12, lastWateredAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, notes: "Needs very little water.", wateringHistory: [])
    ]
}

final class MockRevenueCatService: RevenueCatServiceProtocol {
    func configure() {}
    
    func identifyUser(_ user: User?) async throws -> RevenueCatCustomerState {
        RevenueCatCustomerState(isPremiumActive: user?.plan == "premium", activeEntitlements: user?.plan == "premium" ? ["Plantvia Pro"] : [], appUserId: user.map { String($0.id) })
    }
    
    func fetchSubscriptionStatus(token: String) async throws -> SubscriptionStatusResponse {
        SubscriptionStatusResponse(plan: "premium", user: User(id: 1, nickname: "Preview", email: "preview@plantvia.app", plan: "premium"))
    }
    
    func syncSubscriptionWithBackend(token: String) async throws -> SubscriptionStatusResponse {
        SubscriptionStatusResponse(plan: "premium", user: User(id: 1, nickname: "Preview", email: "preview@plantvia.app", plan: "premium"))
    }
    
    func refreshCustomerInfo() async throws -> RevenueCatCustomerState {
        RevenueCatCustomerState(isPremiumActive: true, activeEntitlements: ["Plantvia Pro"], appUserId: "1")
    }
    
    func fetchPlanOptions() async throws -> [RevenueCatPlanOption] {
        [
            RevenueCatPlanOption(plan: .monthly, productId: "plantvia_premium_monthly", packageId: "monthly", localizedPrice: "₺79,99", localizedIntroductoryPrice: nil, hasTrial: false, trialDays: nil),
            RevenueCatPlanOption(plan: .yearly, productId: "plantvia_premium_yearly", packageId: "yearly", localizedPrice: "₺599,99", localizedIntroductoryPrice: "Free", hasTrial: true, trialDays: 7)
        ]
    }
    
    func buy(plan: PremiumPlan) async throws -> RevenueCatCustomerState {
        RevenueCatCustomerState(isPremiumActive: true, activeEntitlements: ["Plantvia Pro"], appUserId: "1")
    }
    
    func restorePurchases() async throws -> RevenueCatCustomerState {
        RevenueCatCustomerState(isPremiumActive: true, activeEntitlements: ["Plantvia Pro"], appUserId: "1")
    }
}

final class MockNotificationService: NotificationServiceProtocol {
    func askPermission() async throws -> Bool { true }
    func readPermissionStatus() async -> UNAuthorizationStatus { .authorized }
    func planPremiumDailyReminder(time: DateComponents) async throws -> Bool { true }
    func cancelPremiumDailyReminder() {}
    func planFreeWeeklyReminder() async throws -> Bool { true }
    func cancelFreeWeeklyReminder() {}
    func startRemoteNotificationRecording() async {}
    func saveDeviceTokenToBE(_ token: String, authToken: String?) async throws {}
    func saveNotificationPreferencesToBackend(premiumDailyEnabled: Bool?, freeWeeklyEnabled: Bool?, time: Date, authToken: String?) async throws {}
    func fetchNotificationPreferences(authToken: String?) async throws -> NotificationPreferenceResponse? {
        NotificationPreferenceResponse(premiumDailyEnabled: true, freeWeeklyEnabled: false, dailyReminderTime: "09:00", timezone: "Europe/Istanbul")
    }
}

final class MockAppConfigService: AppConfigServiceProtocol {
    func fetchAppConfig() async throws -> AppConfig {
        AppConfig(
            platform: "ios",
            latestVersion: "1.0.0",
            minimumSupportedVersion: "1.0.0",
            forceUpdate: true,
            message: "A new version is required to continue using Plantvia.",
            appStoreUrl: "https://apps.apple.com/app/id0000000000"
        )
    }
}

final class MockAdsService: AdsServiceProtocol {
    let bannerAdUnitId = AppEnvironment.shared.admobDebugBannerAdUnitId
    let interstitialAdUnitId = AppEnvironment.shared.admobInterstitialAdUnitId
    
    func configureMobileAds() {}
    func prepareAdsForCurrentUser(isPremiumActive: Bool) async {}
    func prepareInterstitial() {}
    func showInterstitialIfNeeded(isPremiumActive: Bool) {}
    func canShowInterstitial(isPremiumActive: Bool) -> Bool { !isPremiumActive }
}
