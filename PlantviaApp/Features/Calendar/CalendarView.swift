//
//  CalendarView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var plantStore: PlantStore
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var connectivityStore: ConnectivityStore
    @State private var selectedDay = Date()
    
    private var days: [Date] {
        (-3...10).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: Date()) }
    }
    
    private var selectedDayPlants: [Plant] {
        plantStore.plants.filter { Calendar.current.isDate($0.nextWateringDate, inSameDayAs: selectedDay) || ($0.status == .overdue && Calendar.current.isDateInToday(selectedDay)) }
    }
    
    var body: some View {
        ZStack {
            PremiumGradientBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    calendarHeader
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(days, id: \.self) { day in
                                dayButton(day)
                            }
                        }
                    }
                    
                    Text("Selected day".localized).font(.headline)
                    if selectedDayPlants.isEmpty {
                        PlantviaSurface {
                            ContentUnavailableView("No watering".localized, systemImage: "calendar.badge.checkmark", description: Text("No task is planned for this day.".localized))
                        }
                    } else {
                        ForEach(selectedDayPlants) { plant in
                            NavigationLink(destination: PlantDetailView(plant: plant)) {
                                PlantCardView(plant: plant)
                            }
                            .buttonStyle(PressableScaleStyle())
                        }
                    }
                    
                    AdBannerView()
                }
                .padding()
            }
        }
        .navigationTitle("Calendar".localized)
        .task {
            await refreshCalendar()
        }
        .refreshable {
            await refreshCalendar()
        }
    }
    
    private func refreshCalendar() async {
        if connectivityStore.isOnline, let updatedUser = await subscriptionStore.refreshSubscriptionStatus(token: authStore.authToken) {
            authStore.updateActiveUser(updatedUser)
        }
        await plantStore.refreshPlants(token: authStore.authToken, isOnline: connectivityStore.isOnline)
        await plantStore.syncPendingWateringActions(token: authStore.authToken, isOnline: connectivityStore.isOnline)
    }
    
    private var calendarHeader: some View {
        PlantviaSurface {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "calendar")
                    .font(.title2.bold())
                    .foregroundStyle(Color.plantviaPrimary)
                    .frame(width: 52, height: 52)
                    .background(Color.plantviaPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Care calendar".localized)
                        .font(.title3.bold())
                    Text("See watering rhythm by day and catch overdue care early.".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
        }
    }
    
    private func dayButton(_ day: Date) -> some View {
        let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDay)
        let hasTask = plantStore.plants.contains { Calendar.current.isDate($0.nextWateringDate, inSameDayAs: day) }
        
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { selectedDay = day }
        } label: {
            VStack(spacing: 8) {
                Text(day.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption.weight(.bold))
                Text(day.formatted(.dateTime.day()))
                    .font(.title3.bold())
                Circle()
                    .fill(hasTask ? (isSelected ? Color.white : Color.plantviaPrimary) : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(width: 68, height: 86)
            .background(
                isSelected
                ? LinearGradient(colors: [.plantviaPrimary, .plantviaLeaf], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [Color.plantviaElevatedCard.opacity(0.88), Color.plantviaCard.opacity(0.62)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? .white.opacity(0.25) : .white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.plantviaPrimary.opacity(0.28) : .black.opacity(0.05), radius: isSelected ? 18 : 8, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }
}
