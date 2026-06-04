//
//  AuthStore.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation
import Combine

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var activeUser: User?
    @Published private(set) var authToken: String?
    @Published private(set) var refreshToken: String?
    @Published private(set) var status: LoadingState = .idle
    
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
        self.authToken = UserDefaults.standard.string(forKey: "authToken")
        self.refreshToken = UserDefaults.standard.string(forKey: "refreshToken")
        if let userData = UserDefaults.standard.data(forKey: "activeUser") {
            self.activeUser = try? JSONDecoder.plantvia.decode(User.self, from: userData)
        } else {
            self.activeUser = nil
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
            UserDefaults.standard.set(userData, forKey: "activeUser")
        }
    }
    
    private func applySession(_ session: AuthSession) {
        activeUser = session.user
        authToken = session.accessToken
        refreshToken = session.refreshToken
        UserDefaults.standard.set(session.accessToken, forKey: "authToken")
        UserDefaults.standard.set(session.refreshToken, forKey: "refreshToken")
        if let userData = try? JSONEncoder().encode(session.user) {
            UserDefaults.standard.set(userData, forKey: "activeUser")
        }
    }
    
    private func clearSession() {
        activeUser = nil
        authToken = nil
        refreshToken = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "activeUser")
        status = .idle
    }
}
