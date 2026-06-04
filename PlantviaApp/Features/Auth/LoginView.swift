//
//  LoginView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authStore: AuthStore
    @State private var email = "nizamettin@plantvia.app"
    @State private var password = "123456"
    @State private var errorMessage: String?
    @State private var isRegisterPresented = false
    @State private var isForgotPasswordPresented = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumGradientBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        loginHero
                        
                        PlantviaSurface {
                            VStack(spacing: 14) {
                                TextField("Email".localized, text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .plantviaField()
                                
                                SecureField("Password".localized, text: $password)
                                    .plantviaField()
                                
                                if let errorMessage {
                                    Text(errorMessage).font(.footnote).foregroundStyle(.red)
                                }
                                
                                PrimaryButton("Log in".localized, icon: "arrow.right.circle.fill", isLoading: authStore.status.isLoading) {
                                    Task { await login() }
                                }
                                
                                Button("Forgot password".localized) { isForgotPasswordPresented = true }
                                    .font(.footnote.weight(.medium))
                            }
                        }
                        
                        Button("Don't have an account? Register".localized) { isRegisterPresented = true }
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(24)
                }
            }
            .sheet(isPresented: $isRegisterPresented) { RegisterView() }
            .sheet(isPresented: $isForgotPasswordPresented) { ForgotPasswordView() }
        }
    }
    
    private var loginHero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(colors: [.plantviaForest, .plantviaPrimary, .plantviaLeaf.opacity(0.88)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            TimelineView(.animation) { timeline in
                let phase = timeline.date.timeIntervalSinceReferenceDate
                Image(systemName: "leaf.fill")
                    .font(.system(size: 150, weight: .bold))
                    .foregroundStyle(.white.opacity(0.10))
                    .rotationEffect(.degrees(-18 + sin(phase / 4) * 5))
                    .offset(x: 158, y: -24)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Plantvia")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Give your plants a premium care rhythm.".localized)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.80))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(24)
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .plantviaPrimary.opacity(0.28), radius: 28, x: 0, y: 18)
    }
    
    private func login() async {
        errorMessage = nil
        await authStore.login(email: email, password: password)
        if let message = authStore.status.errorMessage {
            errorMessage = message
        }
    }
}
