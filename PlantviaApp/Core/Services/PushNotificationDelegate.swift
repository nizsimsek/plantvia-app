//
//  PushNotificationDelegate.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation

#if canImport(UIKit)
import UIKit

final class PushNotificationDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        NotificationCenter.default.post(name: .apnsDeviceTokenReceived, object: token)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationCenter.default.post(name: .apnsDeviceTokenError, object: error.localizedDescription)
    }
}

extension Notification.Name {
    static let apnsDeviceTokenReceived = Notification.Name("apnsDeviceTokenReceived")
    static let apnsDeviceTokenError = Notification.Name("apnsDeviceTokenError")
}
#endif
