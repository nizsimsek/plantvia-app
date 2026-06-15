//
//  ForgotPasswordView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var authStore: AuthStore
    @State private var email = ""
    @State private var isResetLinkSent = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumGradientBackground()
                VStack(spacing: 18) {
                    PlantviaSurface {
                        VStack(spacing: 14) {
                            Image(systemName: "lock.rotation")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .frame(width: 54, height: 54)
                                .background(LinearGradient(colors: [.plantviaSky, .plantviaPrimary], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            
                            TextField("Your email address".localized, text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .plantviaField()
                            
                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }
                            
                            PrimaryButton(isResetLinkSent ? "Sent".localized : "Send reset link".localized, icon: "paperplane.fill", isLoading: isSubmitting) {
                                Task { await sendReset() }
                            }
                        }
                    }
                }
                .padding()
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Forgot password".localized)
            .toolbar { Button("Close".localized) { dismiss() } }
            .onChange(of: authStore.pendingResetToken) { _, token in
                if token != nil { dismiss() }
            }
        }
    }
    
    private func sendReset() async {
        isSubmitting = true
        errorMessage = nil
        do {
            try await container.authService.forgotPassword(email: email)
            isResetLinkSent = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
