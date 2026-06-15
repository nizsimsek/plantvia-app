//
//  ResetPasswordView.swift
//  PlantviaApp
//

import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var container: AppContainer
    let token: String

    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var isSubmitting = false
    @State private var isSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumGradientBackground()
                VStack(spacing: 18) {
                    PlantviaSurface {
                        VStack(spacing: 14) {
                            Image(systemName: isSuccess ? "checkmark.circle.fill" : "lock.rotation")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .frame(width: 54, height: 54)
                                .background(
                                    LinearGradient(
                                        colors: isSuccess ? [.plantviaPrimary, .plantviaForest] : [.plantviaSky, .plantviaPrimary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .animation(.spring, value: isSuccess)

                            if isSuccess {
                                Text("Your password has been reset. You can now log in with your new password.".localized)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)

                                PrimaryButton("Close".localized, icon: "checkmark") {
                                    dismiss()
                                }
                            } else {
                                SecureField("New password".localized, text: $password)
                                    .plantviaField()

                                SecureField("Confirm new password".localized, text: $passwordConfirm)
                                    .plantviaField()

                                if let errorMessage {
                                    Text(errorMessage)
                                        .font(.footnote)
                                        .foregroundStyle(.red)
                                }

                                PrimaryButton("Reset password".localized, icon: "lock.fill", isLoading: isSubmitting) {
                                    Task { await submit() }
                                }
                                .disabled(password.isEmpty || passwordConfirm.isEmpty)
                            }
                        }
                    }
                }
                .padding()
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Reset password".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isSuccess {
                    Button("Cancel".localized) { dismiss() }
                }
            }
        }
    }

    private func localizedResetError(_ error: Error) -> String {
        let message = error.localizedDescription
        if message.contains("invalid or has already been used") {
            return "This reset link is invalid or has already been used.".localized
        }
        if message.contains("expired") {
            return "This reset link has expired. Please request a new one.".localized
        }
        return message
    }

    private func submit() async {
        guard password == passwordConfirm else {
            errorMessage = "Passwords do not match.".localized
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters.".localized
            return
        }
        isSubmitting = true
        errorMessage = nil
        do {
            try await container.authService.resetPassword(token: token, password: password)
            isSuccess = true
        } catch {
            errorMessage = localizedResetError(error)
        }
        isSubmitting = false
    }
}
