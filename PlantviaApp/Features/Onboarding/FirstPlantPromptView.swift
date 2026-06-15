//
//  FirstPlantPromptView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI

struct FirstPlantPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPlantForm = false

    var body: some View {
        ZStack {
            PremiumGradientBackground()
            VStack(spacing: 32) {
                Spacer()

                iconArea

                textArea

                actionButtons

                Spacer()
            }
            .padding(28)
        }
        .sheet(isPresented: $showPlantForm) {
            NavigationStack {
                PlantFormView()
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var iconArea: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.plantviaPrimary, .plantviaLeaf],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: .plantviaPrimary.opacity(0.30), radius: 28, x: 0, y: 14)

            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 58, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var textArea: some View {
        VStack(spacing: 14) {
            Text("Add your first plant".localized)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text("Track watering schedules, get care reminders, and keep your plants healthy — it all starts with your first plant.".localized)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 10) {
                Label("Set watering frequency and reminders".localized, systemImage: "drop.fill")
                Label("See plant health status at a glance".localized, systemImage: "checkmark.seal.fill")
                Label("Track your complete watering history".localized, systemImage: "calendar")
            }
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            PrimaryButton("Add my first plant".localized, icon: "plus") {
                showPlantForm = true
            }

            Button("Skip for now".localized) {
                dismiss()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}
