//
//  ProfileView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI
#if canImport(RevenueCatUI)
import RevenueCatUI
#endif

struct ProfileView: View {
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var notificationStore: NotificationStore
    @EnvironmentObject private var connectivityStore: ConnectivityStore
    @AppStorage("themeSelector") private var themeSelector: String = ThemeSelector.system.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.english.rawValue
    @State private var nickname = ""
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isAlertPresented = false
    @State private var isCustomerCenterPresented = false
    
    var body: some View {
        ZStack {
            PremiumGradientBackground()
            ScrollView {
                VStack(spacing: 18) {
                    profileHeader
                    profileCard
                    preferencesCard
                    notificationsCard
                    helpCard
                    
                    Button(role: .destructive) {
                        Task { await authStore.logout() }
                    } label: {
                        Label("Log out".localized, systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.plantviaDanger.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .navigationTitle("Profile".localized)
        .onAppear { nickname = authStore.activeUser?.nickname ?? nickname }
        .onChange(of: authStore.activeUser) { _, user in
            nickname = user?.nickname ?? nickname
        }
        .task {
            await refreshProfile()
        }
        .refreshable {
            await refreshProfile()
        }
        .alert(alertTitle, isPresented: $isAlertPresented) {
            Button("OK".localized, role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $isCustomerCenterPresented, onDismiss: {
            Task {
                await syncSubscriptionAfterCustomerCenter()
            }
        }) {
#if canImport(RevenueCatUI)
            CustomerCenterView()
#else
            ContentUnavailableView(
                "RevenueCat SDK is not linked".localized,
                systemImage: "person.crop.circle.badge.exclamationmark",
                description: Text("Resolve the RevenueCatUI Swift Package in Xcode to display Customer Center.".localized)
            )
#endif
        }
    }
    
    private var profileHeader: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(colors: [.plantviaForest, .plantviaPrimary, .plantviaLeaf.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: subscriptionStore.isPremiumActive ? "crown.fill" : "person.crop.circle.fill")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(.white.opacity(0.16))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(authStore.activeUser?.nickname ?? "Plant Lover")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(authStore.activeUser?.email ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                }
                
                PlantviaChip(
                    title: subscriptionStore.isPremiumActive ? "Premium".localized : "Free".localized,
                    icon: subscriptionStore.isPremiumActive ? "crown.fill" : "leaf.fill",
                    tint: .white
                )
            }
            .padding(22)
        }
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .plantviaPrimary.opacity(0.25), radius: 26, x: 0, y: 18)
    }
    
    private var profileCard: some View {
        PlantviaSurface {
            VStack(alignment: .leading, spacing: 12) {
                cardTitle("Profile".localized, icon: "person.fill")
                TextField("Nickname", text: $nickname)
                    .plantviaField()
                PrimaryButton("Save profile".localized, icon: "checkmark.circle.fill", isLoading: authStore.status.isLoading) {
                    Task { await saveProfile() }
                }
                NavigationLink(destination: PremiumView()) {
                    settingRow(title: "Premium status".localized, value: subscriptionStore.isPremiumActive ? "Premium".localized : "Free".localized, icon: "crown.fill", tint: .plantviaPrimary)
                }
                .buttonStyle(PressableScaleStyle())
                Button {
                    isCustomerCenterPresented = true
                } label: {
                    settingRow(title: "Manage subscription".localized, value: nil, icon: "creditcard.fill", tint: .plantviaSky)
                }
                .buttonStyle(PressableScaleStyle())
            }
        }
    }
    
    private var preferencesCard: some View {
        PlantviaSurface {
            VStack(alignment: .leading, spacing: 12) {
                cardTitle("Preferences".localized, icon: "slider.horizontal.3")
                Picker("Theme".localized, selection: $themeSelector) {
                    ForEach(ThemeSelector.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
                Picker("Language".localized, selection: $appLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: appLanguage) { _, newLanguage in
                    Task { await authStore.updateSettings(language: newLanguage) }
                }
            }
        }
    }
    
    private var notificationsCard: some View {
        PlantviaSurface {
            VStack(alignment: .leading, spacing: 12) {
                if subscriptionStore.isPremiumActive {
                    cardTitle("Premium notifications".localized, icon: "bell.badge.fill")
                    Toggle("Daily care notification".localized, isOn: Binding(
                        get: { notificationStore.isDailyPremiumReminderEnabled },
                        set: { isEnabled in
                            Task {
                                await notificationStore.setPremiumDailyReminderEnabled(
                                    isEnabled,
                                    isPremiumActive: true,
                                    authToken: authStore.authToken
                                )
                            }
                        }
                    ))

                    DatePicker("Notification time".localized, selection: Binding(
                        get: { notificationStore.reminderTime },
                        set: { selectedTime in
                            notificationStore.reminderTime = selectedTime
                            Task {
                                await notificationStore.updateReminderTimeIfNeeded(isPremiumActive: true, authToken: authStore.authToken)
                            }
                        }
                    ), displayedComponents: .hourAndMinute)
                    .disabled(!notificationStore.isDailyPremiumReminderEnabled)
                } else {
                    cardTitle("Notifications".localized, icon: "bell.fill")
                    Toggle("Weekly watering reminder".localized, isOn: Binding(
                        get: { notificationStore.isFreeWeeklyReminderEnabled },
                        set: { isEnabled in
                            Task {
                                await notificationStore.setFreeWeeklyReminderEnabled(isEnabled, authToken: authStore.authToken)
                            }
                        }
                    ))
                    Text("Get a weekly reminder every Sunday at 10:00 to check on your plants.".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    NavigationLink(destination: PremiumView()) {
                        settingRow(title: "Get daily notifications with Premium".localized, value: nil, icon: "crown.fill", tint: .plantviaWarning)
                    }
                    .buttonStyle(PressableScaleStyle())
                }

                if let errorMessage = notificationStore.status.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
    }
    
    private var helpCard: some View {
        PlantviaSurface {
            NavigationLink(destination: AboutView()) {
                settingRow(title: "About".localized, value: nil, icon: "info.circle.fill", tint: .plantviaLavender)
            }
            .buttonStyle(PressableScaleStyle())
        }
    }
    
    private func cardTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.plantviaPrimary)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
    
    private func settingRow(title: String, value: String?, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12))
                .clipShape(Circle())
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            if let value {
                Text(value)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
            }
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private func refreshProfile() async {
        if connectivityStore.isOnline, let updatedUser = await subscriptionStore.refreshSubscriptionStatus(token: authStore.authToken) {
            authStore.updateActiveUser(updatedUser)
            nickname = updatedUser.nickname
        }
        await notificationStore.refreshPermissionStatus()
        if connectivityStore.isOnline {
            await notificationStore.refreshNotificationPreferences(authToken: authStore.authToken, isPremiumActive: subscriptionStore.isPremiumActive)
        }
    }
    
    private func syncSubscriptionAfterCustomerCenter() async {
        await subscriptionStore.refreshRevenueCatCustomerInfo()
        
        if connectivityStore.isOnline, let updatedUser = await subscriptionStore.syncSubscriptionWithBackend(token: authStore.authToken) {
            authStore.updateActiveUser(updatedUser)
            nickname = updatedUser.nickname
        }
        
        await notificationStore.syncWithPremiumStatus(isPremiumActive: subscriptionStore.isPremiumActive)
    }
    
    private func saveProfile() async {
        guard connectivityStore.isOnline else {
            presentProfileAlert(title: "Could not update profile".localized, message: "Profile update requires an internet connection.".localized)
            return
        }
        
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedNickname.count >= 2 else {
            presentProfileAlert(title: "Missing information".localized, message: "Nickname must be at least 2 characters.".localized)
            return
        }
        
        await authStore.updateProfile(nickname: trimmedNickname)
        if let errorMessage = authStore.status.errorMessage {
            presentProfileAlert(title: "Could not update profile".localized, message: errorMessage)
        } else {
            nickname = authStore.activeUser?.nickname ?? trimmedNickname
            presentProfileAlert(title: "Profile updated".localized, message: "Your profile information was saved.".localized)
        }
    }
    
    private func presentProfileAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        isAlertPresented = true
    }
}

private struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        ZStack {
            PremiumGradientBackground()
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    missionCard
                    featuresCard
                    appInfoCard
                }
                .padding()
            }
        }
        .navigationTitle("About".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.plantviaForest, .plantviaPrimary, .plantviaLeaf.opacity(0.86)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Image(systemName: "leaf.fill")
                .font(.system(size: 150, weight: .bold))
                .foregroundStyle(.white.opacity(0.08))
                .rotationEffect(.degrees(-18))
                .offset(x: 160, y: -22)
            
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Plantvia")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Grow Up Your Plants".localized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                }
            }
            .padding(24)
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .plantviaPrimary.opacity(0.24), radius: 24, x: 0, y: 16)
    }
    
    private var missionCard: some View {
        PlantviaSurface {
            VStack(alignment: .leading, spacing: 10) {
                aboutTitle("Why Plantvia?".localized, icon: "sparkle.magnifyingglass")
                Text("Plantvia simplifies plant care with calendar tracking, watering history, smart reminders, and AI-assisted suggestions.".localized)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var featuresCard: some View {
        PlantviaSurface {
            VStack(alignment: .leading, spacing: 14) {
                aboutTitle("What you can do".localized, icon: "checklist")
                aboutFeature("Track every plant's care rhythm".localized, icon: "leaf.fill", tint: .plantviaPrimary)
                aboutFeature("See watering days on a clear calendar".localized, icon: "calendar", tint: .plantviaSky)
                aboutFeature("Review watering history and notes".localized, icon: "clock.arrow.circlepath", tint: .plantviaWarning)
                aboutFeature("Use AI analysis with Premium".localized, icon: "sparkles", tint: .plantviaLavender)
            }
        }
    }
    
    private var appInfoCard: some View {
        PlantviaSurface {
            VStack(alignment: .leading, spacing: 12) {
                aboutTitle("App information".localized, icon: "info.circle.fill")
                infoRow("Version".localized, value: "\(appVersion) (\(buildNumber))")
                infoRow("Default language".localized, value: "English".localized)
                infoRow("Made for".localized, value: "iPhone".localized)
            }
        }
    }
    
    private func aboutTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.plantviaPrimary)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
    
    private func aboutFeature(_ title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12))
                .clipShape(Circle())
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
    }
    
    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}
