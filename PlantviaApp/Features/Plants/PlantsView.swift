//
//  PlantsView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI

struct PlantsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var plantStore: PlantStore
    @EnvironmentObject private var connectivityStore: ConnectivityStore
    @State private var search = ""
    @State private var filter: PlantStatus?
    
    private var filteredPlants: [Plant] {
        plantStore.plants.filter { plant in
            let searchResults = search.isEmpty || plant.name.localizedCaseInsensitiveContains(search) || plant.species.localizedCaseInsensitiveContains(search)
            let statusResults = filter == nil || plant.status == filter
            return searchResults && statusResults
        }
    }
    
    var body: some View {
        ZStack {
            PremiumGradientBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    libraryHeader
                    filterChips
                    
                    if filteredPlants.isEmpty {
                        PlantviaSurface {
                            ContentUnavailableView("Plant not found".localized, systemImage: "magnifyingglass", description: Text("Try changing your search or filter.".localized))
                        }
                    } else {
                        ForEach(filteredPlants) { plant in
                            NavigationLink(destination: PlantDetailView(plant: plant)) {
                                PlantCardView(plant: plant)
                            }
                            .buttonStyle(PressableScaleStyle())
                        }
                    }
                }
                .padding()
            }
        }
        .searchable(text: $search, prompt: "Search plant or species".localized)
        .navigationTitle("My Plants".localized)
        .task {
            await plantStore.refreshPlants(token: authStore.authToken, isOnline: connectivityStore.isOnline)
        }
        .refreshable {
            await plantStore.refreshPlants(token: authStore.authToken, isOnline: connectivityStore.isOnline)
            await plantStore.syncPendingWateringActions(token: authStore.authToken, isOnline: connectivityStore.isOnline)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await plantStore.refreshPlants(token: authStore.authToken, isOnline: connectivityStore.isOnline)
                await plantStore.syncPendingWateringActions(token: authStore.authToken, isOnline: connectivityStore.isOnline)
            }
        }
        .toolbar {
            NavigationLink(destination: PlantFormView()) {
                Image(systemName: "plus.circle.fill")
            }
        }
    }
    
    private var libraryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("My Plants".localized)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Spacer()
                Text("\(plantStore.plants.count)")
                    .font(.title3.bold())
                    .foregroundStyle(Color.plantviaPrimary)
                    .frame(width: 46, height: 46)
                    .background(Color.plantviaPrimary.opacity(0.12))
                    .clipShape(Circle())
            }
            
            Text("Search, filter, and keep every plant's rhythm visible.".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterButton(title: "All".localized, icon: "square.grid.2x2.fill", value: nil)
                filterButton(title: PlantStatus.healthy.displayName, icon: PlantStatus.healthy.icon, value: .healthy)
                filterButton(title: PlantStatus.needsWatering.displayName, icon: PlantStatus.needsWatering.icon, value: .needsWatering)
                filterButton(title: PlantStatus.overdue.displayName, icon: PlantStatus.overdue.icon, value: .overdue)
            }
            .padding(.vertical, 2)
        }
    }
    
    private func filterButton(title: String, icon: String, value: PlantStatus?) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                filter = value
            }
        } label: {
            PlantviaChip(
                title: title,
                icon: icon,
                tint: value?.tintColor ?? .plantviaPrimary,
                isSelected: filter == value
            )
        }
        .buttonStyle(.plain)
    }
}

struct PlantCardView: View {
    let plant: Plant
    
    private var daysUntilWatering: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: plant.nextWateringDate)).day ?? 0
    }
    
    private var careCaption: String {
        if plant.status == .overdue { return "Care is overdue".localized }
        if plant.status == .needsWatering { return "Water today".localized }
        return L10n.format("%d days left", max(daysUntilWatering, 0))
    }
    
    var body: some View {
        PlantviaSurface {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    PlantImageView(plant: plant, size: 86, cornerRadius: 24)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(plant.name)
                            .font(.title3.bold())
                            .lineLimit(1)
                        Text(plant.species.isEmpty ? "Unknown species".localized : plant.species)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Label(plant.location.displayName, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    
                    Image(systemName: plant.status.icon)
                        .foregroundStyle(plant.status.tintColor)
                        .frame(width: 34, height: 34)
                        .background(plant.status.tintColor.opacity(0.12))
                        .clipShape(Circle())
                }
                
                HStack(spacing: 10) {
                    PlantviaChip(title: L10n.format("%d days", plant.wateringFrequencyDays), icon: "repeat", tint: .plantviaPrimary)
                    Spacer()
                    PlantviaChip(title: plant.status.displayName, icon: nil, tint: plant.status.tintColor)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(plant.status.tintColor)
                    Text(careCaption)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
    }
}
