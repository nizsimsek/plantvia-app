//
//  NotificationService.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

protocol NotificationServiceProtocol {
    func askPermission() async throws -> Bool
    func readPermissionStatus() async -> UNAuthorizationStatus
    func planPremiumDailyReminder(time: DateComponents) async throws -> Bool
    func cancelPremiumDailyReminder()
    func planFreeWeeklyReminder() async throws -> Bool
    func cancelFreeWeeklyReminder()
    func startRemoteNotificationRecording() async
    func saveDeviceTokenToBE(_ token: String, authToken: String?) async throws
    func saveNotificationPreferencesToBackend(premiumDailyEnabled: Bool?, freeWeeklyEnabled: Bool?, time: Date, authToken: String?) async throws
    func fetchNotificationPreferences(authToken: String?) async throws -> NotificationPreferenceResponse?
}

final class NotificationService: NotificationServiceProtocol {
    private let premiumDailyReminderId = "PREMIUM_DAILY_PLANT_CARE_REMINDER"
    private let freeWeeklyReminderId  = "FREE_WEEKLY_PLANT_CARE_REMINDER"
    
    func askPermission() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    }
    
    func readPermissionStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
    
    func planPremiumDailyReminder(time: DateComponents) async throws -> Bool {
        let hasPermission = try await askPermission()
        guard hasPermission else { return false }
        
        let content = UNMutableNotificationContent()
        content.title = "Today's plant care is ready".localized
        content.body = "Your plants may need you today. Check your care plan.".localized
        content.sound = .default
        content.categoryIdentifier = "PLANTVIA_PREMIUM_DAILY_CARE"
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: premiumDailyReminderId, content: content, trigger: trigger)
        
        cancelPremiumDailyReminder()
        try await UNUserNotificationCenter.current().add(request)
        return true
    }
    
    func cancelPremiumDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [premiumDailyReminderId])
    }

    func planFreeWeeklyReminder() async throws -> Bool {
        let hasPermission = try await askPermission()
        guard hasPermission else { return false }

        let content = UNMutableNotificationContent()
        content.title = "Check your plants this week".localized
        content.body = "Your plants may need some attention. Open Plantvia to review their care schedule.".localized
        content.sound = .default
        content.categoryIdentifier = "PLANTVIA_FREE_WEEKLY_CARE"

        var weekday = DateComponents()
        weekday.weekday = 1
        weekday.hour = 10
        weekday.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: weekday, repeats: true)
        let request = UNNotificationRequest(identifier: freeWeeklyReminderId, content: content, trigger: trigger)

        cancelFreeWeeklyReminder()
        try await UNUserNotificationCenter.current().add(request)
        return true
    }

    func cancelFreeWeeklyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [freeWeeklyReminderId])
    }
    
    @MainActor
    func startRemoteNotificationRecording() async {
#if canImport(UIKit)
        UIApplication.shared.registerForRemoteNotifications()
#endif
    }
    
    func saveDeviceTokenToBE(_ token: String, authToken: String?) async throws {
        guard let authToken else { return }
        let request = DeviceTokenRegisterRequest(
            token: token,
            platform: "ios",
            environment: Self.apnsEnvironment,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        )
        let _: APIEnvelope<EmptyAPIData> = try await APIClient.shared.request("notifications/devices", method: "POST", body: request, token: authToken)
    }
    
    func saveNotificationPreferencesToBackend(premiumDailyEnabled: Bool?, freeWeeklyEnabled: Bool?, time: Date, authToken: String?) async throws {
        guard let authToken else { return }
        let timeText = Self.timeFormatter.string(from: time)
        let request = NotificationPreferenceRequest(
            premiumDailyEnabled: premiumDailyEnabled,
            freeWeeklyEnabled: freeWeeklyEnabled,
            dailyReminderTime: timeText,
            timezone: TimeZone.current.identifier
        )
        let _: APIEnvelope<EmptyAPIData> = try await APIClient.shared.request("notifications/preferences", method: "PUT", body: request, token: authToken)
    }
    
    func fetchNotificationPreferences(authToken: String?) async throws -> NotificationPreferenceResponse? {
        guard let authToken else { return nil }
        let envelope: APIEnvelope<NotificationPreferenceResponse> = try await APIClient.shared.request("notifications/preferences", token: authToken)
        return envelope.data
    }
    
    private static var apnsEnvironment: String {
#if DEBUG
        "sandbox"
#else
        "production"
#endif
    }
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

struct DeviceTokenRegisterRequest: Encodable {
    let token: String
    let platform: String
    let environment: String
    let appVersion: String?
}

struct NotificationPreferenceRequest: Encodable {
    let premiumDailyEnabled: Bool?
    let freeWeeklyEnabled: Bool?
    let dailyReminderTime: String
    let timezone: String
}

struct NotificationPreferenceResponse: Decodable {
    let premiumDailyEnabled: Bool
    let freeWeeklyEnabled: Bool
    let dailyReminderTime: String
    let timezone: String

    enum CodingKeys: String, CodingKey {
        case premiumDailyEnabled
        case freeWeeklyEnabled
        case dailyReminderTime
        case timezone
    }

    init(premiumDailyEnabled: Bool, freeWeeklyEnabled: Bool = false, dailyReminderTime: String, timezone: String) {
        self.premiumDailyEnabled = premiumDailyEnabled
        self.freeWeeklyEnabled = freeWeeklyEnabled
        self.dailyReminderTime = dailyReminderTime
        self.timezone = timezone
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        premiumDailyEnabled = Self.decodeFlexibleBool(from: container, forKey: .premiumDailyEnabled)
        freeWeeklyEnabled = Self.decodeFlexibleBool(from: container, forKey: .freeWeeklyEnabled)
        dailyReminderTime = try container.decodeIfPresent(String.self, forKey: .dailyReminderTime) ?? "09:00"
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone) ?? TimeZone.current.identifier
    }
    
    private static func decodeFlexibleBool(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Bool {
        if let value = try? container.decode(Bool.self, forKey: key) { return value }
        if let value = try? container.decode(Int.self, forKey: key) { return value != 0 }
        if let value = try? container.decode(String.self, forKey: key) {
            return ["true", "1", "yes"].contains(value.lowercased())
        }
        return false
    }
}
