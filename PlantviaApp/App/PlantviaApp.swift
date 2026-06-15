//
//  PlantviaApp.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI
#if canImport(Sentry)
import Sentry
#endif

@main
struct PlantviaApp: App {
#if canImport(UIKit)
    @UIApplicationDelegateAdaptor(PushNotificationDelegate.self) private var pushNotificationDelegate
#endif
    
    @StateObject private var container: AppContainer
    @StateObject private var onboardingStore: OnboardingStore
    @StateObject private var authStore: AuthStore
    @StateObject private var plantStore: PlantStore
    @StateObject private var subscriptionStore: SubscriptionStore
    @StateObject private var notificationStore: NotificationStore
    @StateObject private var connectivityStore: ConnectivityStore
    @StateObject private var appUpdateStore: AppUpdateStore
    @AppStorage("themeSelector") private var themeSelector: String = ThemeSelector.system.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.english.rawValue
    
    init() {
        let container = AppContainer()
        container.revenueCatService.configure()
        container.adsService.configureMobileAds()
        container.analyticsService.configure()
#if canImport(Sentry)
        if let dsn = AppEnvironment.shared.sentryDsn, !dsn.isEmpty {
            SentrySDK.start { options in
                options.dsn = dsn
                options.environment = "production"
                options.tracesSampleRate = 0.1
            }
        }
#endif
        _container = StateObject(wrappedValue: container)
        _onboardingStore = StateObject(wrappedValue: OnboardingStore())
        _authStore = StateObject(wrappedValue: AuthStore(authService: container.authService))
        _plantStore = StateObject(wrappedValue: PlantStore(plantService: container.plantService))
        _subscriptionStore = StateObject(wrappedValue: SubscriptionStore(revenueCatService: container.revenueCatService))
        _notificationStore = StateObject(wrappedValue: NotificationStore(notificationService: container.notificationService))
        _connectivityStore = StateObject(wrappedValue: ConnectivityStore())
        _appUpdateStore = StateObject(wrappedValue: AppUpdateStore(appConfigService: container.appConfigService))
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
                .environmentObject(onboardingStore)
                .environmentObject(authStore)
                .environmentObject(plantStore)
                .environmentObject(subscriptionStore)
                .environmentObject(notificationStore)
                .environmentObject(connectivityStore)
                .environmentObject(appUpdateStore)
                .preferredColorScheme(ThemeSelector(rawValue: themeSelector)?.colorScheme)
                .id(appLanguage)
                .task(id: authStore.activeUser?.id) {
                    await subscriptionStore.identifyRevenueCatUser(authStore.activeUser)
                    if let user = authStore.activeUser {
                        container.analyticsService.identify(userId: String(user.id), plan: user.plan ?? "free")
                    } else {
                        container.analyticsService.reset()
                    }
                }
                .task(id: authStore.authToken) {
                    await notificationStore.syncRemoteNotificationRegistrationIfPossible(authToken: authStore.authToken)
                }
#if canImport(UIKit)
                .onReceive(NotificationCenter.default.publisher(for: .apnsDeviceTokenReceived)) { notification in
                    guard let token = notification.object as? String else { return }
                    Task {
                        await notificationStore.deviceTokenReceived(token, authToken: authStore.authToken)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .apnsDeviceTokenError)) { notification in
                    guard let message = notification.object as? String else { return }
                    notificationStore.deviceTokenRegistrationFailed(message)
                }
#endif
        }
    }
}
