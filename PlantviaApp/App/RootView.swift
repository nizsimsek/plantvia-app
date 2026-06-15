//
//  RootView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var onboardingStore: OnboardingStore
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var connectivityStore: ConnectivityStore
    @EnvironmentObject private var appUpdateStore: AppUpdateStore

    var body: some View {
        Group {
            if let requiredUpdate = appUpdateStore.requiredUpdate {
                ForceUpdateView(config: requiredUpdate)
            } else if !onboardingStore.completed {
                OnboardingView()
            } else if authStore.activeUser == nil {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .task {
            await appUpdateStore.checkForRequiredUpdate(isOnline: connectivityStore.isOnline)
        }
        .onChange(of: connectivityStore.isOnline) { _, isOnline in
            guard isOnline else { return }
            Task {
                await appUpdateStore.checkForRequiredUpdate(isOnline: true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionExpired)) { _ in
            authStore.handleExpiredSession()
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: onboardingStore.completed)
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: authStore.activeUser?.id)
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: appUpdateStore.requiredUpdate?.minimumSupportedVersion)
        .sheet(isPresented: Binding(
            get: { authStore.pendingResetToken != nil },
            set: { if !$0 { authStore.pendingResetToken = nil } }
        )) {
            if let token = authStore.pendingResetToken {
                ResetPasswordView(token: token)
            }
        }
        .onOpenURL { url in
            guard url.scheme == "plantvia",
                  url.host == "reset-password",
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let token = components.queryItems?.first(where: { $0.name == "token" })?.value
            else { return }
            authStore.pendingResetToken = token
        }
    }
}
