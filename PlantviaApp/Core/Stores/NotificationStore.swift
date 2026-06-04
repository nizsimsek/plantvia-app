//
//  NotificationStore.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationStore: ObservableObject {
    @Published var isDailyPremiumReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDailyPremiumReminderEnabled, forKey: dailyPremiumReminderKey)
        }
    }
    @Published var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime, forKey: reminderTimeKey)
        }
    }
    @Published private(set) var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var latestDeviceToken: String?
    @Published private(set) var status: LoadingState = .idle
    
    private let notificationService: NotificationServiceProtocol
    private let dailyPremiumReminderKey = "isDailyPremiumReminderEnabled"
    private let reminderTimeKey = "reminderTime"
    private let latestDeviceTokenKey = "latestDeviceToken"
    
    init(notificationService: NotificationServiceProtocol) {
        self.notificationService = notificationService
        self.isDailyPremiumReminderEnabled = UserDefaults.standard.bool(forKey: dailyPremiumReminderKey)
        self.reminderTime = UserDefaults.standard.object(forKey: reminderTimeKey) as? Date ?? Self.defaultReminderTime
        self.latestDeviceToken = UserDefaults.standard.string(forKey: latestDeviceTokenKey)
    }
    
    func refreshPermissionStatus() async {
        permissionStatus = await notificationService.readPermissionStatus()
    }
    
    func syncRemoteNotificationRegistrationIfPossible(authToken: String?) async {
        await refreshPermissionStatus()
        
        if permissionStatus == .authorized || permissionStatus == .provisional || permissionStatus == .ephemeral {
            await notificationService.startRemoteNotificationRecording()
        }
        
        await syncLatestDeviceTokenToBackend(authToken: authToken)
    }
    
    func refreshNotificationPreferences(authToken: String?, isPremiumActive: Bool) async {
        do {
            guard let preferences = try await notificationService.fetchNotificationPreferences(authToken: authToken) else {
                await syncWithPremiumStatus(isPremiumActive: isPremiumActive)
                return
            }
            
            isDailyPremiumReminderEnabled = isPremiumActive && preferences.premiumDailyEnabled
            reminderTime = Self.reminderTimeFormatter.date(from: preferences.dailyReminderTime) ?? reminderTime
            await syncWithPremiumStatus(isPremiumActive: isPremiumActive)
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }
    
    func setPremiumDailyReminderEnabled(_ isEnabled: Bool, isPremiumActive: Bool, authToken: String? = nil) async {
        guard isPremiumActive else {
            isDailyPremiumReminderEnabled = false
            notificationService.cancelPremiumDailyReminder()
            status = .failure("Daily AI and care notifications are Premium only.".localized)
            return
        }
        
        isDailyPremiumReminderEnabled = isEnabled
        if isEnabled {
            let didPlanReminder = await plan()
            guard didPlanReminder else {
                isDailyPremiumReminderEnabled = false
                status = .failure("Notification permission is required for Premium reminders.".localized)
                return
            }
            try? await notificationService.saveNotificationPreferencesToBackend(isEnabled: true, time: reminderTime, authToken: authToken)
            await notificationService.startRemoteNotificationRecording()
            await syncLatestDeviceTokenToBackend(authToken: authToken)
        } else {
            notificationService.cancelPremiumDailyReminder()
            try? await notificationService.saveNotificationPreferencesToBackend(isEnabled: false, time: reminderTime, authToken: authToken)
            status = .success
        }
    }
    
    func updateReminderTimeIfNeeded(isPremiumActive: Bool, authToken: String? = nil) async {
        guard isDailyPremiumReminderEnabled else { return }
        await setPremiumDailyReminderEnabled(true, isPremiumActive: isPremiumActive, authToken: authToken)
    }
    
    func syncWithPremiumStatus(isPremiumActive: Bool) async {
        if isPremiumActive && isDailyPremiumReminderEnabled {
            _ = await plan()
        }
        
        if !isPremiumActive {
            isDailyPremiumReminderEnabled = false
            notificationService.cancelPremiumDailyReminder()
        }
    }
    
    private func plan() async -> Bool {
        status = .loading
        do {
            let time = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            let didPlanReminder = try await notificationService.planPremiumDailyReminder(time: time)
            await refreshPermissionStatus()
            status = didPlanReminder ? .success : .failure("Notification permission is required for Premium reminders.".localized)
            return didPlanReminder
        } catch {
            status = .failure(error.localizedDescription)
            return false
        }
    }
    
    func deviceTokenReceived(_ token: String, authToken: String?) async {
        latestDeviceToken = token
        UserDefaults.standard.set(token, forKey: latestDeviceTokenKey)
        await syncLatestDeviceTokenToBackend(authToken: authToken)
    }
    
    func deviceTokenRegistrationFailed(_ message: String) {
        status = .failure(message)
    }
    
    private func syncLatestDeviceTokenToBackend(authToken: String?) async {
        guard let token = latestDeviceToken, let authToken else { return }
        do {
            try await notificationService.saveDeviceTokenToBE(token, authToken: authToken)
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }
    
    private static var defaultReminderTime: Date {
        Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    }
    
    private static let reminderTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
