//
//  DashboardView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var plantStore: PlantStore
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var connectivityStore: ConnectivityStore
    
    private var plantsNeedingWaterToday: [Plant] {
        plantStore.plantsNeedingWaterToday
    }
    
    var body: some View {
        ZStack {
            PremiumGradientBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    dashboardHero
                    
                    HStack {
                        statusCard("Healthy".localized, number: plantStore.plants.filter { $0.status == .healthy }.count, icon: "checkmark.seal.fill", color: .plantviaPrimary)
                        statusCard("Needs watering".localized, number: plantStore.plants.filter { $0.status == .needsWatering }.count, icon: "drop.fill", color: .plantviaSky)
                        statusCard("Overdue".localized, number: plantStore.plants.filter { $0.status == .overdue }.count, icon: "exclamationmark.triangle.fill", color: .plantviaDanger)
                    }
                    
                    PlantviaSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("Plants to water today".localized, icon: "drop.degreesign.fill")
                            if plantsNeedingWaterToday.isEmpty {
                                emptyTodayView
                            } else {
                                ForEach(plantsNeedingWaterToday) { plant in
                                    NavigationLink(destination: PlantDetailView(plant: plant)) {
                                        PlantRowView(plant: plant)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Quick actions".localized, icon: "bolt.fill")
                        HStack {
                            NavigationLink(destination: PlantFormView()) { action("Add plant".localized, icon: "plus", tint: .plantviaPrimary) }
                            NavigationLink(destination: AIAssistantView(showsCloseButton: true)) { action("Ask AI".localized, icon: "sparkles", tint: .plantviaLavender) }
                            NavigationLink(destination: CalendarView()) { action("Calendar".localized, icon: "calendar", tint: .plantviaSky) }
                        }
                    }
                    
                    AdBannerView()
                }
                .padding()
            }
            .refreshable {
                await refreshDashboard()
            }
        }
        .navigationTitle("Today".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await refreshDashboard()
        }
    }
    
    private var dashboardHero: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.plantviaForest, .plantviaPrimary, .plantviaLeaf.opacity(0.86)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            TimelineView(.animation) { timeline in
                let phase = timeline.date.timeIntervalSinceReferenceDate
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0), .white.opacity(0.20), .white.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .rotationEffect(.degrees(-18))
                    .offset(x: CGFloat(sin(phase / 2.8)) * 90, y: CGFloat(cos(phase / 3.4)) * 28)
                    .blendMode(.softLight)
            }
            
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    PlantviaChip(
                        title: subscriptionStore.isPremiumActive ? "Premium".localized : "Free".localized,
                        icon: subscriptionStore.isPremiumActive ? "crown.fill" : "leaf.fill",
                        tint: .white,
                        isSelected: false
                    )
                    Spacer()
                    Image(systemName: "leaf.arrow.triangle.circlepath")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.92))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.format("Welcome, %@", authStore.activeUser?.nickname ?? "Plant Lover"))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                    
                    Text("We prepared a calm and clear care plan for your plants today.".localized)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.80))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack(spacing: 10) {
                    heroMetric("\(plantStore.plants.count)", title: "Plants".localized)
                    heroMetric("\(plantsNeedingWaterToday.count)", title: "Today".localized)
                }
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 250)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .plantviaPrimary.opacity(0.30), radius: 30, x: 0, y: 20)
    }
    
    private func heroMetric(_ value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
    }
    
    private var emptyTodayView: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(Color.plantviaPrimary)
                .frame(width: 42, height: 42)
                .background(Color.plantviaPrimary.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("All calm today".localized)
                    .font(.headline)
                Text("No plants need watering right now.".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
    
    private func refreshDashboard() async {
        if connectivityStore.isOnline, let updatedUser = await subscriptionStore.refreshSubscriptionStatus(token: authStore.authToken) {
            authStore.updateActiveUser(updatedUser)
        }
        await plantStore.refreshPlants(token: authStore.authToken, isOnline: connectivityStore.isOnline)
        await plantStore.syncPendingWateringActions(token: authStore.authToken, isOnline: connectivityStore.isOnline)
    }
    
    private func statusCard(_ title: String, number: Int, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.bold())
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.13))
                .clipShape(Circle())
            Text("\(number)")
                .font(.title.bold())
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(color.opacity(0.16), lineWidth: 1)
        )
    }
    
    private func action(_ title: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3.bold())
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.14))
                .clipShape(Circle())
            Text(title)
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tint.opacity(0.14), lineWidth: 1)
        )
    }
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.plantviaPrimary)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
}
