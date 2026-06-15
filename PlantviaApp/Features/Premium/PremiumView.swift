//
//  PremiumView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var notificationStore: NotificationStore
    @State private var selectedPlan: PremiumPlan = .yearly
    
    private let features = [
        "Unlimited plants",
        "AI plant analysis",
        "Advanced calendar",
        "Watering history",
        "Smart suggestions",
        "Ad-free usage"
    ]
    
    var body: some View {
        ZStack {
            PremiumGradientBackground()
            ScrollView {
                VStack(spacing: 20) {
                    header
                    
                    PlantviaSurface {
                        VStack(spacing: 12) {
                            ForEach(features, id: \.self) { feature in
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.plantviaPrimary)
                                    Text(feature.localized)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(PremiumPlan.allCases) { plan in
                            planCard(for: plan)
                        }
                    }
                    
                    if let message = subscriptionStore.status.errorMessage {
                        errorBanner(message)
                    }
                    
                    PrimaryButton(primaryButtonTitle, icon: "crown.fill", isLoading: subscriptionStore.status.isLoading) {
                        Task { await buySelectedPlan() }
                    }

                    if let opt = selectedOption, opt.hasTrial, let days = opt.trialDays {
                        Text(L10n.format("After %d days, %@ will be charged. Cancel anytime.", days, opt.localizedPrice))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button("Restore purchases".localized) {
                        Task { await restorePurchases() }
                    }
                    .font(.footnote.weight(.medium))
                }
                .padding()
            }
        }
        .navigationTitle("Premium".localized)
        .task {
            await subscriptionStore.loadPlanOptions()
            await subscriptionStore.refreshRevenueCatCustomerInfo()
            await notificationStore.syncWithPremiumStatus(isPremiumActive: subscriptionStore.isPremiumActive)
        }
    }
    
    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 78, height: 78)
                .background(
                    LinearGradient(colors: [.plantviaPrimary, .plantviaLeaf, .plantviaLavender], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
                .shadow(color: .plantviaPrimary.opacity(0.28), radius: 24, x: 0, y: 14)
            
            Text("Plantvia Premium".localized)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            
            if anyPlanHasTrial {
                Text("Try free, then enjoy unlimited plants, AI, and an ad-free experience.".localized)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            } else {
                Text("More plants, more analysis, and an ad-free care experience.".localized)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var selectedOption: RevenueCatPlanOption? { option(for: selectedPlan) }

    private var primaryButtonTitle: String {
        guard let option = selectedOption else { return "Go Premium".localized }
        if option.hasTrial, let days = option.trialDays {
            return L10n.format("Start %d-day free trial", days)
        }
        return L10n.format("Continue with %@", option.localizedPrice)
    }

    private var anyPlanHasTrial: Bool {
        subscriptionStore.planOptions.contains { $0.hasTrial }
    }
    
    private func planCard(for plan: PremiumPlan) -> some View {
        let option = option(for: plan)
        let isSelected = selectedPlan == plan
        
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                selectedPlan = plan
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.plantviaPrimary : Color.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if plan == .yearly {
                            Text("Best value".localized)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .foregroundStyle(.white)
                                .background(Color.plantviaPrimary)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(planDescription(for: plan))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    Text(option?.localizedPrice ?? plan.price)
                        .font(.headline.bold())
                        .foregroundStyle(Color.plantviaPrimary)

                    if let opt = option, opt.hasTrial, let days = opt.trialDays {
                        Text(L10n.format("%d days free", days))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.plantviaLeaf)
                            .clipShape(Capsule())
                    } else if let introductoryPrice = option?.localizedIntroductoryPrice {
                        Text(L10n.format("Intro: %@", introductoryPrice))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.plantviaPrimary : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message.localized)
                .font(.footnote)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func option(for plan: PremiumPlan) -> RevenueCatPlanOption? {
        subscriptionStore.planOptions.first { $0.plan == plan }
    }
    
    private func planDescription(for plan: PremiumPlan) -> String {
        switch plan {
            case .monthly:
                return "Flexible monthly access".localized
            case .yearly:
                return "Best for long-term plant care".localized
        }
    }
    
    private func buySelectedPlan() async {
        if let updatedUser = await subscriptionStore.buy(plan: selectedPlan, token: authStore.authToken) {
            authStore.updateActiveUser(updatedUser)
            if updatedUser.plan == "premium" {
                dismiss()
            }
        }
        await notificationStore.syncWithPremiumStatus(isPremiumActive: subscriptionStore.isPremiumActive)
    }
    
    private func restorePurchases() async {
        if let updatedUser = await subscriptionStore.restorePurchases(token: authStore.authToken) {
            authStore.updateActiveUser(updatedUser)
            if updatedUser.plan == "premium" {
                dismiss()
            }
        }
        await notificationStore.syncWithPremiumStatus(isPremiumActive: subscriptionStore.isPremiumActive)
    }
}
