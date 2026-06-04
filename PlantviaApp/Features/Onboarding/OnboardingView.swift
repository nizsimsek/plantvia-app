//
//  OnboardingView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var onboardingStore: OnboardingStore
    @State private var page = 0
    
    private let pages = [
        ("Track your plants beautifully", "Keep every plant's location, species, care notes, and watering rhythm in one place.", "leaf.circle.fill"),
        ("Never miss watering", "See what needs watering today, this week, and this month with a calendar-first view.", "drop.circle.fill"),
        ("AI plant assistant", "Upload a photo and get Turkish care suggestions about leaves, soil, light, and watering.", "sparkles"),
        ("Premium care experience", "Unlimited plants, AI assistant, advanced history, and an ad-free experience.", "crown.fill")
    ]
    
    var body: some View {
        ZStack {
            PremiumGradientBackground()
            VStack(spacing: 24) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        VStack(spacing: 28) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(colors: [.plantviaPrimary, .plantviaLeaf, .plantviaLavender.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 164, height: 164)
                                    .shadow(color: .plantviaPrimary.opacity(0.28), radius: 34, x: 0, y: 20)
                                
                                TimelineView(.animation) { timeline in
                                    let phase = timeline.date.timeIntervalSinceReferenceDate
                                    Circle()
                                        .stroke(.white.opacity(0.28), lineWidth: 1.4)
                                        .frame(width: 194, height: 194)
                                        .scaleEffect(1 + sin(phase / 2.4) * 0.035)
                                }
                                
                                Image(systemName: pages[index].2)
                                    .font(.system(size: 70, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .symbolEffect(.pulse, value: page)
                            }
                            
                            Text(pages[index].0.localized)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.80)
                            
                            Text(pages[index].1.localized)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.horizontal, 26)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                
                PrimaryButton(page == pages.count - 1 ? "Get Started".localized : "Continue".localized, icon: "arrow.right") {
                    if page == pages.count - 1 {
                        onboardingStore.complete()
                    } else {
                        withAnimation { page += 1 }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
            }
        }
    }
}
