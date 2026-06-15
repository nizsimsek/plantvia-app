//
//  AuthStore.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation
import Combine

enum UserDefaultsKey: String {
    case activeUser
}

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var activeUser: User?
    @Published private(set) var authToken: String?
    @Published private(set) var refreshToken: String?
    @Published private(set) var status: LoadingState = .idle
    @Published var pendingResetToken: String?

    private let authService: AuthServiceProtocol
    private static let keychainService = "plantvia"

    init(authService: AuthServiceProtocol) {
        self.authService = authService

        self.authToken = KeychainHelper.shared.load(service: Self.keychainService, account: "authToken")
        self.refreshToken = KeychainHelper.shared.load(service: Self.keychainService, account: "refreshToken")

        if let userData = UserDefaults.standard.data(forKey: UserDefaultsKey.activeUser.rawValue) {
            self.activeUser = try? JSONDecoder.plantvia.decode(User.self, from: userData)
        }

        migrateTokensFromUserDefaultsIfNeeded()

        // ARCH-003: Silent token refresh on 401
        APIClient.onTokenRefreshNeeded = { [weak self] in
            guard let self else { throw APIError.server("Session expired") }
            return try await self.performTokenRefresh()
        }
    }

    func login(email: String, password: String) async {
        status = .loading
        do {
            let session = try await authService.login(email: email, password: password)
            applySession(session)
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    func register(nickname: String, email: String, password: String) async {
        status = .loading
        do {
            let session = try await authService.register(nickname: nickname, email: email, password: password)
            applySession(session)
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    func updateProfile(nickname: String) async {
        guard let authToken else {
            status = .failure("Session was not found.".localized)
            return
        }

        status = .loading
        do {
            let user = try await authService.updateProfile(nickname: nickname, token: authToken)
            updateActiveUser(user)
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    func updateSettings(language: String) async {
        guard let authToken else { return }
        do {
            let user = try await authService.updateSettings(language: language, token: authToken)
            updateActiveUser(user)
        } catch {
            // Language update failure is non-critical — ignore silently
        }
    }

    func logout() async {
        if let refreshToken {
            try? await authService.logout(refreshToken: refreshToken)
        }
        clearSession()
    }

    func handleExpiredSession() {
        clearSession()
        status = .failure("Your session has expired. Please log in again.".localized)
    }

    func updateActiveUser(_ user: User) {
        activeUser = user
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: UserDefaultsKey.activeUser.rawValue)
        }
    }

    private func performTokenRefresh() async throws -> String {
        guard let rt = refreshToken else {
            throw APIError.server("No refresh token available")
        }
        let session = try await authService.refresh(refreshToken: rt)
        applySession(session)
        return session.accessToken
    }

    private func applySession(_ session: AuthSession) {
        activeUser = session.user
        authToken = session.accessToken
        refreshToken = session.refreshToken
        KeychainHelper.shared.save(session.accessToken, service: Self.keychainService, account: "authToken")
        KeychainHelper.shared.save(session.refreshToken, service: Self.keychainService, account: "refreshToken")
        if let userData = try? JSONEncoder().encode(session.user) {
            UserDefaults.standard.set(userData, forKey: UserDefaultsKey.activeUser.rawValue)
        }
        if let lang = session.user.language, !lang.isEmpty,
           UserDefaults.standard.string(forKey: "appLanguage") == nil {
            UserDefaults.standard.set(lang, forKey: "appLanguage")
        }
    }

    private func clearSession() {
        activeUser = nil
        authToken = nil
        refreshToken = nil
        KeychainHelper.shared.delete(service: Self.keychainService, account: "authToken")
        KeychainHelper.shared.delete(service: Self.keychainService, account: "refreshToken")
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.activeUser.rawValue)
        status = .idle
    }

    private func migrateTokensFromUserDefaultsIfNeeded() {
        if let oldToken = UserDefaults.standard.string(forKey: "authToken") {
            KeychainHelper.shared.save(oldToken, service: Self.keychainService, account: "authToken")
            UserDefaults.standard.removeObject(forKey: "authToken")
            authToken = oldToken
        }
        if let oldToken = UserDefaults.standard.string(forKey: "refreshToken") {
            KeychainHelper.shared.save(oldToken, service: Self.keychainService, account: "refreshToken")
            UserDefaults.standard.removeObject(forKey: "refreshToken")
            refreshToken = oldToken
        }
    }
}
