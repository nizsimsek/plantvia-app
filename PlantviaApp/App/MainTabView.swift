//
//  MainTabView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var plantStore: PlantStore
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var notificationStore: NotificationStore
    @EnvironmentObject private var connectivityStore: ConnectivityStore
    @EnvironmentObject private var container: AppContainer
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { DashboardView() }
                .tabItem { Label("Today".localized, systemImage: "leaf.fill") }
                .tag(0)
            
            NavigationStack { PlantsView() }
                .tabItem { Label("Plants".localized, systemImage: "tree.fill") }
                .tag(1)
            
            NavigationStack { CalendarView() }
                .tabItem { Label("Calendar".localized, systemImage: "calendar") }
                .tag(2)
            
            NavigationStack { AIAssistantView() }
                .tabItem { Label("AI", systemImage: "sparkles") }
                .tag(3)
            
            NavigationStack { ProfileView() }
                .tabItem { Label("Profile".localized, systemImage: "person.crop.circle") }
                .tag(4)
        }
        .tint(.plantviaPrimary)
        .task(id: authStore.authToken) {
            await refreshServerState(isInitialLoad: true)
        }
        .onChange(of: selectedTab) { _, tab in
            guard [0, 1, 2, 3, 4].contains(tab) else { return }
            Task {
                await refreshServerState(isInitialLoad: false)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await refreshServerState(isInitialLoad: false)
            }
        }
        .onChange(of: connectivityStore.isOnline) { _, isOnline in
            guard isOnline else { return }
            Task {
                await refreshServerState(isInitialLoad: false)
            }
        }
    }
    
    private func refreshServerState(isInitialLoad: Bool) async {
        if connectivityStore.isOnline {
            if let updatedUser = await subscriptionStore.refreshSubscriptionStatus(token: authStore.authToken) {
                authStore.updateActiveUser(updatedUser)
            } else {
                subscriptionStore.syncWithUserPlan(authStore.activeUser?.plan)
            }
        } else {
            subscriptionStore.syncWithUserPlan(authStore.activeUser?.plan)
        }
        
        if isInitialLoad {
            await plantStore.loadPlants(token: authStore.authToken, isOnline: connectivityStore.isOnline)
        } else {
            await plantStore.refreshPlants(token: authStore.authToken, isOnline: connectivityStore.isOnline)
        }
        
        await plantStore.syncPendingWateringActions(token: authStore.authToken, isOnline: connectivityStore.isOnline)
        
        if connectivityStore.isOnline {
            await notificationStore.refreshNotificationPreferences(authToken: authStore.authToken, isPremiumActive: subscriptionStore.isPremiumActive)
        }
        
        await container.adsService.prepareAdsForCurrentUser(isPremiumActive: subscriptionStore.isPremiumActive)
    }
}
