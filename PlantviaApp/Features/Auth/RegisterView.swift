//
//  RegisterView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authStore: AuthStore
    @State private var nickname = ""
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumGradientBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        PlantviaSurface {
                            VStack(alignment: .leading, spacing: 12) {
                                Image(systemName: "person.badge.plus")
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 54, height: 54)
                                    .background(LinearGradient(colors: [.plantviaPrimary, .plantviaLeaf], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                Text("Create account".localized)
                                    .font(.title.bold())
                                Text("Start tracking plants, watering rhythm, and care history.".localized)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        PlantviaSurface {
                            VStack(spacing: 14) {
                                TextField("Nickname", text: $nickname)
                                    .plantviaField()
                                TextField("Email".localized, text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .plantviaField()
                                SecureField("Password".localized, text: $password)
                                    .plantviaField()
                                
                                if let errorMessage = authStore.status.errorMessage {
                                    Text(errorMessage)
                                        .font(.footnote)
                                        .foregroundStyle(.red)
                                }
                                
                                PrimaryButton("Create account".localized, icon: "person.badge.plus", isLoading: authStore.status.isLoading) {
                                    Task {
                                        await authStore.register(nickname: nickname, email: email, password: password)
                                        if authStore.status.errorMessage == nil {
                                            dismiss()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Register".localized)
        }
    }
}
