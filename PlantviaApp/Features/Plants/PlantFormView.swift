//
//  PlantFormView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI
import PhotosUI
import UIKit

struct PlantFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var plantStore: PlantStore
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var connectivityStore: ConnectivityStore
    @State private var name = ""
    @State private var species = ""
    @State private var location: PlantLocation = .salon
    @State private var wateringFrequencyDays = 7
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isAlertPresented = false
    @State private var shouldShowPremiumAction = false
    @State private var isPremiumPresented = false
    
    private let freePlantLimit = 3
    private let plantToEdit: Plant?
    
    init(plantToEdit: Plant? = nil) {
        self.plantToEdit = plantToEdit
        _name = State(initialValue: plantToEdit?.name ?? "")
        _species = State(initialValue: plantToEdit?.species ?? "")
        _location = State(initialValue: plantToEdit?.location ?? .salon)
        _wateringFrequencyDays = State(initialValue: plantToEdit?.wateringFrequencyDays ?? 7)
        _notes = State(initialValue: plantToEdit?.notes ?? "")
    }
    
    var body: some View {
        ZStack {
            PremiumGradientBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    basicInformationCard
                    photoCard
                    wateringRoutineCard
                    notesCard
                    
                    if !connectivityStore.isOnline {
                        Label((plantToEdit == nil ? "Plant creation requires an internet connection." : "Plant editing requires an internet connection.").localized, systemImage: "wifi.slash")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    PrimaryButton((plantToEdit == nil ? "Save" : "Update plant").localized, icon: "checkmark.circle.fill", isLoading: plantStore.status.isLoading) {
                        Task { await submitForm() }
                    }
                }
                .padding()
            }
        }
        .navigationTitle((plantToEdit == nil ? "Add plant" : "Edit plant").localized)
        .onChange(of: selectedPhoto) { _, selectedItem in
            Task {
                selectedImageData = try? await selectedItem?.loadTransferable(type: Data.self)
            }
        }
        .alert(alertTitle, isPresented: $isAlertPresented) {
            Button("OK".localized, role: .cancel) {}
            if shouldShowPremiumAction {
                Button("Go Premium".localized) {
                    isPremiumPresented = true
                }
            }
        } message: {
            Text(alertMessage)
        }
        .navigationDestination(isPresented: $isPremiumPresented) {
            PremiumView()
        }
    }
    
    private var header: some View {
        PlantviaSurface {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    Image(systemName: plantToEdit == nil ? "plus" : "pencil")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(
                            LinearGradient(colors: [.plantviaForest, .plantviaPrimary, .plantviaLeaf], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.plantviaPrimary.opacity(0.24), radius: 14, x: 0, y: 8)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text((plantToEdit == nil ? "New Plant" : "Edit plant").localized)
                            .font(.title2.bold())
                        Text("Create a care rhythm that is easy to follow.".localized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        summaryPill(title: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Plant name".localized : name, icon: "leaf.fill", tint: .plantviaPrimary)
                        summaryPill(title: L10n.format("Every %d days", wateringFrequencyDays), icon: "repeat", tint: .plantviaSky)
                    }
                }
            }
        }
    }
    
    private var basicInformationCard: some View {
        PlantviaSurface {
            VStack(alignment: .leading, spacing: 12) {
                formTitle("Basic information".localized, icon: "leaf.fill")
                VStack(alignment: .leading, spacing: 8) {
                    fieldCaption("Required".localized)
                    TextField("Plant name".localized, text: $name)
                        .textInputAutocapitalization(.words)
                        .plantviaField()
                }
                TextField("Species".localized, text: $species)
                    .textInputAutocapitalization(.words)
                    .plantviaField()
                locationSelector
            }
        }
    }
    
    private var photoCard: some View {
        PlantviaSurface {
            VStack(alignment: .leading, spacing: 12) {
                formTitle("Photo".localized, icon: "photo.on.rectangle")
                
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    ZStack(alignment: .bottomLeading) {
                        widePhotoPreview
                        
                        HStack(spacing: 10) {
                            Image(systemName: selectedImageData == nil ? "camera.fill" : "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(Color.black.opacity(0.26))
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectedImageData == nil ? "Choose photo".localized : "Photo selected".localized)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text("Make sure leaves, soil, and the overall plant are clear.".localized)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.82))
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(
                            LinearGradient(colors: [.black.opacity(0.48), .black.opacity(0.05)], startPoint: .bottom, endPoint: .top)
                        )
                    }
                }
                .buttonStyle(PressableScaleStyle())
            }
        }
    }
    
    private var photoPreview: some View {
        Group {
            if let selectedImageData, let image = UIImage(data: selectedImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "camera.macro")
                    .font(.title2)
                    .foregroundStyle(Color.plantviaPrimary)
            }
        }
        .frame(width: 62, height: 62)
        .background(
            LinearGradient(colors: [.plantviaMint.opacity(0.52), .plantviaSky.opacity(0.22)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private var widePhotoPreview: some View {
        Group {
            if let selectedImageData, let image = UIImage(data: selectedImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [.plantviaMint.opacity(0.72), .plantviaSky.opacity(0.34), .plantviaLavender.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "camera.macro")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(Color.plantviaForest.opacity(0.72))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 178)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.24), lineWidth: 1)
        )
    }
    
    private var wateringRoutineCard: some View {
        PlantviaSurface {
            VStack(alignment: .leading, spacing: 14) {
                formTitle("Watering routine".localized, icon: "drop.fill")
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(L10n.format("Every %d days", wateringFrequencyDays))
                            .font(.headline)
                        Spacer()
                        Stepper("", value: $wateringFrequencyDays, in: 1...30)
                            .labelsHidden()
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([1, 2, 3, 7, 10, 14], id: \.self) { day in
                                Button {
                                    wateringFrequencyDays = day
                                } label: {
                                    PlantviaChip(
                                        title: day == 1 ? "Daily".localized : L10n.format("%d days", day),
                                        icon: nil,
                                        tint: .plantviaPrimary,
                                        isSelected: wateringFrequencyDays == day
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var notesCard: some View {
        PlantviaSurface {
            VStack(alignment: .leading, spacing: 12) {
                formTitle("Notes".localized, icon: "note.text")
                TextEditor(text: $notes)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(Color.plantviaElevatedCard.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
    
    private func formTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.plantviaPrimary)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
    
    private func fieldCaption(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
    
    private func summaryPill(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .foregroundStyle(tint)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }
    
    private var locationSelector: some View {
        Menu {
            ForEach(PlantLocation.allCases) { locationOption in
                Button {
                    location = locationOption
                } label: {
                    Label(locationOption.displayName, systemImage: locationOption == location ? "checkmark" : "circle")
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.headline)
                    .foregroundStyle(Color.plantviaPrimary)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Location".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(location.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                
                Spacer(minLength: 12)
                
                Image(systemName: "chevron.down")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .padding(.horizontal, 14)
            .background(Color.plantviaElevatedCard.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.20), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private func submitForm() async {
        guard validateForm() else { return }
        guard validateOnlineMutation() else { return }
        
        if let plantToEdit {
            await plantStore.updatePlant(
                plantToEdit,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                species: species,
                imageData: selectedImageData,
                location: location,
                wateringFrequencyDays: wateringFrequencyDays,
                reminderTime: effectiveReminderTime,
                notes: notes,
                token: authStore.authToken,
                isOnline: connectivityStore.isOnline
            )
        } else {
            guard validateFreePlantLimit() else { return }
            await plantStore.addPlant(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                species: species,
                imageData: selectedImageData,
                location: location,
                wateringFrequencyDays: wateringFrequencyDays,
                reminderTime: effectiveReminderTime,
                notes: notes,
                token: authStore.authToken,
                isOnline: connectivityStore.isOnline
            )
        }
        if let errorMessage = plantStore.status.errorMessage {
            presentError(message: errorMessage)
        } else {
            dismiss()
        }
    }
    
    private func validateForm() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            presentValidationError(message: "Please enter a plant name.".localized)
            return false
        }
        
        return true
    }
    
    private func validateOnlineMutation() -> Bool {
        guard connectivityStore.isOnline else {
            presentValidationError(message: (plantToEdit == nil ? "Plant creation requires an internet connection." : "Plant editing requires an internet connection.").localized)
            return false
        }
        
        return true
    }
    
    private func validateFreePlantLimit() -> Bool {
        let isFreeUser = !subscriptionStore.isPremiumActive
        if isFreeUser && plantStore.plants.count >= freePlantLimit {
            presentPremiumLimitError(message: L10n.format("Free plan supports up to %d plants. Upgrade to Premium for unlimited plants.", freePlantLimit))
            return false
        }
        
        return true
    }
    
    private func presentValidationError(message: String) {
        shouldShowPremiumAction = false
        alertTitle = "Missing information".localized
        alertMessage = message
        isAlertPresented = true
    }
    
    private func presentError(message: String) {
        let isPremiumLimitError = message.localizedCaseInsensitiveContains("Free plan supports up to") || message.localizedCaseInsensitiveContains("Free plan en fazla")
        if isPremiumLimitError {
            presentPremiumLimitError(message: message)
            return
        }
        
        shouldShowPremiumAction = false
        alertTitle = "Could not save plant".localized
        alertMessage = message
        isAlertPresented = true
    }
    
    private func presentPremiumLimitError(message: String) {
        shouldShowPremiumAction = true
        alertTitle = "Free plant limit reached".localized
        alertMessage = message
        isAlertPresented = true
    }
    
    private var effectiveReminderTime: Date {
        Self.defaultReminderTime
    }
    
    private static var defaultReminderTime: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
}
