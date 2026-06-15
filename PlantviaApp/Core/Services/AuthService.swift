//
//  AuthService.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> AuthSession
    func register(nickname: String, email: String, password: String) async throws -> AuthSession
    func refresh(refreshToken: String) async throws -> AuthSession
    func forgotPassword(email: String) async throws
    func resetPassword(token: String, password: String) async throws
    func updateProfile(nickname: String, token: String) async throws -> User
    func updateSettings(language: String, token: String) async throws -> User
    func logout(refreshToken: String) async throws
}

final class AuthService: AuthServiceProtocol {
    func login(email: String, password: String) async throws -> AuthSession {
        let request = LoginRequest(email: email, password: password)
        let envelope: APIEnvelope<AuthSession> = try await APIClient.shared.request("auth/login", method: "POST", body: request)
        guard let session = envelope.data else { throw APIError.server(envelope.message) }
        return session
    }
    
    func register(nickname: String, email: String, password: String) async throws -> AuthSession {
        let request = RegisterRequest(nickname: nickname, email: email, password: password)
        let envelope: APIEnvelope<AuthSession> = try await APIClient.shared.request("auth/register", method: "POST", body: request)
        guard let session = envelope.data else { throw APIError.server(envelope.message) }
        return session
    }
    
    func refresh(refreshToken: String) async throws -> AuthSession {
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        let envelope: APIEnvelope<AuthSession> = try await APIClient.shared.request("auth/refresh", method: "POST", body: request)
        guard let session = envelope.data else { throw APIError.server(envelope.message) }
        return session
    }

    func forgotPassword(email: String) async throws {
        let request = ForgotPasswordRequest(email: email)
        let _: APIEnvelope<EmptyAPIData> = try await APIClient.shared.request("auth/forgot-password", method: "POST", body: request)
    }

    func resetPassword(token: String, password: String) async throws {
        let request = ResetPasswordRequest(token: token, password: password)
        let _: APIEnvelope<EmptyAPIData> = try await APIClient.shared.request("auth/reset-password", method: "POST", body: request)
    }
    
    func updateProfile(nickname: String, token: String) async throws -> User {
        let request = UpdateProfileRequest(nickname: nickname)
        let envelope: APIEnvelope<User> = try await APIClient.shared.request("users/me", method: "PATCH", body: request, token: token)
        guard let user = envelope.data else { throw APIError.server(envelope.message) }
        return user
    }

    func updateSettings(language: String, token: String) async throws -> User {
        let request = UpdateSettingsRequest(language: language)
        let envelope: APIEnvelope<User> = try await APIClient.shared.request("users/settings", method: "PUT", body: request, token: token)
        guard let user = envelope.data else { throw APIError.server(envelope.message) }
        return user
    }
    
    func logout(refreshToken: String) async throws {
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        let _: APIEnvelope<EmptyAPIData> = try await APIClient.shared.request("auth/logout", method: "POST", body: request)
    }
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let nickname: String
    let email: String
    let password: String
}

struct ForgotPasswordRequest: Encodable {
    let email: String
}

struct UpdateProfileRequest: Encodable {
    let nickname: String
}

struct UpdateSettingsRequest: Encodable {
    let language: String
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

struct ResetPasswordRequest: Encodable {
    let token: String
    let password: String
}
