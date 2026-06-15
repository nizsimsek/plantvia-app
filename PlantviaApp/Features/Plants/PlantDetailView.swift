//
//  PlantDetailView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI

struct PlantDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var plantStore: PlantStore
    @EnvironmentObject private var connectivityStore: ConnectivityStore
    let plant: Plant
    @State private var isDeleteConfirmationPresented = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isAlertPresented = false
    
    private var activePlant: Plant? {
        plantStore.findPlant(id: plant.id)
    }
    
    var body: some View {
        Group {
            if let activePlant {
                ZStack {
                    PremiumGradientBackground()
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            detailHero(activePlant)
                        
                            PlantviaSurface {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack {
                                        Label(activePlant.status.displayName, systemImage: activePlant.status.icon)
                                            .font(.headline)
                                            .foregroundStyle(activePlant.status.tintColor)
                                        Spacer()
                                        PlantviaChip(title: L10n.format("%d days", activePlant.wateringFrequencyDays), icon: "repeat", tint: .plantviaPrimary)
                                    }
                                    
                                    Divider().opacity(0.55)
                                    
                                    dateRow("Last watered".localized, date: activePlant.lastWateredAt, icon: "drop.fill")
                                    dateRow("Next watering".localized, date: activePlant.nextWateringDate, icon: "calendar.badge.clock")
                                    careSummaryRow(activePlant)
                                }
                            }
                        
                            PrimaryButton("Watered today".localized, icon: "drop.fill") {
                                Task {
                                    await plantStore.todayWatered(plant: activePlant, token: authStore.authToken, isOnline: connectivityStore.isOnline)
                                }
                            }
                        
                            if !connectivityStore.isOnline {
                                Label("Offline watering will sync when internet is back.".localized, systemImage: "arrow.triangle.2.circlepath")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        
                            aiCallToAction(activePlant)
                        
                            Text("Notes".localized).font(.headline)
                            PlantviaSurface {
                                Text(activePlant.notes.isEmpty ? "No notes yet.".localized : activePlant.notes)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        
                            Text("Watering history".localized).font(.headline)
                            PlantviaSurface {
                                let history = plantStore.selectedPlantHistory[activePlant.id] ?? activePlant.wateringHistory
                                if history.isEmpty {
                                    Label("No watering recorded yet.".localized, systemImage: "drop.slash")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    VStack(spacing: 14) {
                                        ForEach(history) { data in
                                            HStack(alignment: .top, spacing: 12) {
                                                Circle()
                                                    .fill(Color.plantviaPrimary)
                                                    .frame(width: 10, height: 10)
                                                    .padding(.top, 6)
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(data.wateredAt.appFormatted()).font(.subheadline.bold())
                                                    Text(data.note).font(.caption).foregroundStyle(.secondary)
                                                    if data.isPending {
                                                        Label("Sync pending".localized, systemImage: "clock.arrow.circlepath")
                                                            .font(.caption2.weight(.semibold))
                                                            .foregroundStyle(Color.plantviaWarning)
                                                    }
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                .refreshable {
                    await refreshDetail()
                }
            } else {
                ContentUnavailableView("Plant not found".localized, systemImage: "leaf", description: Text("This plant may have been deleted or is no longer available.".localized))
            }
        }
        .navigationTitle("Plant detail".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let activePlant {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink(destination: PlantFormView(plantToEdit: activePlant)) {
                        Image(systemName: "pencil")
                    }
                    Button(role: .destructive) {
                        isDeleteConfirmationPresented = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .confirmationDialog("Delete plant?".localized, isPresented: $isDeleteConfirmationPresented, titleVisibility: .visible) {
            Button("Delete".localized, role: .destructive) {
                Task { await deleteActivePlant() }
            }
            Button("Cancel".localized, role: .cancel) {}
        } message: {
            Text("This plant and its watering history will be deleted.".localized)
        }
        .alert(alertTitle, isPresented: $isAlertPresented) {
            Button("OK".localized, role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .task {
            await refreshDetail()
        }
    }
    
    private func detailHero(_ activePlant: Plant) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            plantHeroImage(activePlant)
                .frame(height: 270)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(.white.opacity(0.28), lineWidth: 1)
                )
                .shadow(color: activePlant.status.tintColor.opacity(0.25), radius: 26, x: 0, y: 18)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(activePlant.name)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .lineLimit(2)
                            .minimumScaleFactor(0.80)
                        Text(activePlant.species.isEmpty ? "Unknown species".localized : activePlant.species)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: activePlant.status.icon)
                        .foregroundStyle(activePlant.status.tintColor)
                        .frame(width: 44, height: 44)
                        .background(activePlant.status.tintColor.opacity(0.13))
                        .clipShape(Circle())
                }
                
                HStack(spacing: 10) {
                    PlantviaChip(title: activePlant.location.displayName, icon: "mappin.and.ellipse", tint: .plantviaPrimary)
                    PlantviaChip(title: activePlant.status.displayName, icon: nil, tint: activePlant.status.tintColor)
                }
            }
            .padding(18)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.20), lineWidth: 1)
            )
            .padding(.top, -28)
            .padding(.horizontal, 12)
        }
    }
    
    private func careSummaryRow(_ activePlant: Plant) -> some View {
        let daysLeft = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: activePlant.nextWateringDate)
        ).day ?? 0
        let caption: String = {
            if activePlant.status == .overdue { return "Care is overdue".localized }
            if activePlant.status == .needsWatering { return "Water today".localized }
            return L10n.format("%d days left", max(daysLeft, 0))
        }()
        
        return HStack(spacing: 12) {
            Image(systemName: activePlant.status.icon)
                .foregroundStyle(activePlant.status.tintColor)
                .frame(width: 34, height: 34)
                .background(activePlant.status.tintColor.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Care rhythm".localized)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(caption)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(activePlant.status.tintColor)
            }
            Spacer()
        }
    }
    
    private func dateRow(_ title: String, date: Date, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.plantviaPrimary)
                .frame(width: 34, height: 34)
                .background(Color.plantviaPrimary.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(date.appFormatted(dateStyle: .long, timeStyle: .short))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
            }
            Spacer()
        }
    }
    
    private func aiCallToAction(_ activePlant: Plant) -> some View {
        NavigationLink(destination: AIAssistantView(plantId: activePlant.id, startQuestion: L10n.format("Care suggestion for %@?", activePlant.name), showsCloseButton: true)) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        LinearGradient(colors: [.plantviaLavender, .plantviaPrimary], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Ask AI about this plant".localized)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Photo, watering, soil, and leaf clues in one answer.".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(PressableScaleStyle())
    }
    
    private func refreshDetail() async {
        await plantStore.refreshPlants(token: authStore.authToken, isOnline: connectivityStore.isOnline)
        await plantStore.syncPendingWateringActions(token: authStore.authToken, isOnline: connectivityStore.isOnline)
        guard let activePlant else {
            plantStore.clearWateringHistory(for: plant.id)
            return
        }
        await plantStore.loadWateringHistory(for: activePlant, token: authStore.authToken, isOnline: connectivityStore.isOnline)
    }
    
    private func deleteActivePlant() async {
        guard let activePlant else { return }
        await plantStore.deletePlant(activePlant, token: authStore.authToken, isOnline: connectivityStore.isOnline)
        if let errorMessage = plantStore.status.errorMessage {
            alertTitle = "Could not delete plant".localized
            alertMessage = errorMessage
            isAlertPresented = true
        } else {
            dismiss()
        }
    }
    
    private func plantHeroImage(_ activePlant: Plant) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.plantviaForest, .plantviaPrimary.opacity(0.82), .plantviaMint.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(maxWidth: .infinity, maxHeight: 270)
            .overlay {
                if let url = APIClient.shared.imageURL(forPath: activePlant.imageUrl) {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .id(activePlant.imageUrl)
                } else {
                    Image(systemName: activePlant.imageName)
                        .font(.system(size: 92))
                        .foregroundStyle(.white)
                }
            }
            .clipped()
    }
}
