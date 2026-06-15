//
//  PlantStore.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation
import Combine

@MainActor
final class PlantStore: ObservableObject {
    @Published private(set) var plants: [Plant]
    @Published private(set) var status: LoadingState = .idle
    @Published private(set) var selectedPlantHistory: [Int: [WateringLog]] = [:]
    @Published private(set) var pendingWateringActions: [PendingWateringAction]
    
    private let plantService: PlantServiceProtocol
    private let cachedPlantsKey = "cachedPlants"
    private let pendingWateringActionsKey = "pendingWateringActions"
    
    init(plantService: PlantServiceProtocol, plants: [Plant] = []) {
        self.plantService = plantService
        self.plants = plants.isEmpty ? Self.loadCachedPlants() : plants
        self.pendingWateringActions = Self.loadPendingWateringActions()
    }
    
    var plantsNeedingWaterToday: [Plant] {
        plants.filter { $0.status == .needsWatering || $0.status == .overdue }
    }
    
    func findPlant(id: Int) -> Plant? {
        plants.first { $0.id == id }
    }
    
    func clearWateringHistory(for plantId: Int) {
        selectedPlantHistory[plantId] = nil
    }
    
    func loadPlants(token: String?, isOnline: Bool = true, showLoading: Bool = true) async {
        guard let token else {
            plants = []
            selectedPlantHistory = [:]
            pendingWateringActions = []
            savePlantsToCache()
            savePendingWateringActions()
            status = .idle
            return
        }

        guard isOnline else {
            plants = Self.loadCachedPlants()
            pendingWateringActions = Self.loadPendingWateringActions()
            status = .success
            return
        }

        if showLoading { status = .loading }
        do {
            plants = try await plantService.fetchPlants(token: token)
            mergePendingWateringActionsIntoPlants()
            savePlantsToCache()
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    func refreshPlants(token: String?, isOnline: Bool = true) async {
        await loadPlants(token: token, isOnline: isOnline, showLoading: false)
    }
    
    func addPlant(name: String, species: String, imageData: Data?, location: PlantLocation, wateringFrequencyDays: Int, reminderTime: Date, notes: String, token: String?, isOnline: Bool = true) async {
        guard let token else {
            status = .failure("Session was not found.".localized)
            return
        }
        
        guard isOnline else {
            status = .failure("Plant creation requires an internet connection.".localized)
            return
        }
        
        status = .loading
        do {
            let uploadedFile = try await uploadImageIfNeeded(imageData, token: token)
            let request = PlantMutationRequest(
                name: name.isEmpty ? "New Plant".localized : name,
                species: species,
                imageUrl: uploadedFile?.url,
                location: location.rawValue,
                wateringFrequencyDays: wateringFrequencyDays,
                reminderTime: DateFormatter.plantviaHourMinute.string(from: reminderTime),
                lastWateredAt: ISO8601DateFormatter().string(from: Date()),
                notes: notes
            )
            let plant = try await plantService.createPlant(request, token: token)
            plants.insert(plant, at: 0)
            savePlantsToCache()
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }
    
    func updatePlant(_ plant: Plant, name: String, species: String, imageData: Data?, location: PlantLocation, wateringFrequencyDays: Int, reminderTime: Date, notes: String, token: String?, isOnline: Bool = true) async {
        guard let token else {
            status = .failure("Session was not found.".localized)
            return
        }
        
        guard isOnline else {
            status = .failure("Plant editing requires an internet connection.".localized)
            return
        }
        
        status = .loading
        do {
            let uploadedFile = try await uploadImageIfNeeded(imageData, token: token)
            let request = PlantMutationRequest(
                name: name.isEmpty ? plant.name : name,
                species: species,
                imageUrl: uploadedFile?.url ?? plant.imageUrl,
                location: location.rawValue,
                wateringFrequencyDays: wateringFrequencyDays,
                reminderTime: DateFormatter.plantviaHourMinute.string(from: reminderTime),
                lastWateredAt: ISO8601DateFormatter().string(from: plant.lastWateredAt),
                notes: notes
            )
            let updatedPlant = try await plantService.updatePlant(plantId: plant.id, request, token: token)
            if let index = plants.firstIndex(where: { $0.id == plant.id }) {
                plants[index] = updatedPlant
            }
            savePlantsToCache()
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }
    
    func deletePlant(_ plant: Plant, token: String?, isOnline: Bool = true) async {
        guard let token else {
            status = .failure("Session was not found.".localized)
            return
        }
        
        guard isOnline else {
            status = .failure("Plant deletion requires an internet connection.".localized)
            return
        }
        
        status = .loading
        do {
            try await plantService.deletePlant(plantId: plant.id, token: token)
            plants.removeAll { $0.id == plant.id }
            selectedPlantHistory[plant.id] = nil
            pendingWateringActions.removeAll { $0.plantId == plant.id }
            savePendingWateringActions()
            savePlantsToCache()
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }
    
    func todayWatered(plant: Plant, token: String?, isOnline: Bool = true) async {
        guard let token else {
            status = .failure("Session was not found.".localized)
            return
        }
        
        guard let index = plants.firstIndex(where: { $0.id == plant.id }) else { return }
        
        if !isOnline {
            markWateringAsPending(plantIndex: index)
            return
        }
        
        status = .loading
        do {
            let newRecord = try await plantService.waterPlant(plantId: plant.id, wateredAt: Date(), note: "Watered today".localized, token: token)
            plants[index].lastWateredAt = newRecord.wateredAt
            plants[index].wateringHistory.insert(newRecord, at: 0)
            selectedPlantHistory[plant.id, default: []].insert(newRecord, at: 0)
            savePlantsToCache()
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }
    
    func loadWateringHistory(for plant: Plant, token: String?, isOnline: Bool = true) async {
        guard let token, isOnline else {
            selectedPlantHistory[plant.id] = plant.wateringHistory
            return
        }
        do {
            let history = try await plantService.fetchWateringHistory(plantId: plant.id, token: token)
            let pendingLogs = pendingWateringActions
                .filter { $0.plantId == plant.id }
                .map { WateringLog(id: $0.localLogId, wateredAt: $0.wateredAt, note: $0.note, isPending: true) }
            selectedPlantHistory[plant.id] = pendingLogs + history
            if let index = plants.firstIndex(where: { $0.id == plant.id }) {
                plants[index].wateringHistory = pendingLogs + history
            }
            savePlantsToCache()
        } catch {
            status = .failure(error.localizedDescription)
        }
    }
    
    func syncPendingWateringActions(token: String?, isOnline: Bool) async {
        guard let token, isOnline, !pendingWateringActions.isEmpty else { return }
        
        var syncedActionIds: Set<UUID> = []
        for action in pendingWateringActions {
            do {
                let syncedLog = try await plantService.waterPlant(plantId: action.plantId, wateredAt: action.wateredAt, note: action.note, token: token)
                replacePendingWateringLog(action: action, syncedLog: syncedLog)
                syncedActionIds.insert(action.id)
            } catch {
                incrementPendingRetryCount(actionId: action.id)
            }
        }
        
        pendingWateringActions.removeAll { syncedActionIds.contains($0.id) }
        savePendingWateringActions()
        savePlantsToCache()
    }
    
    private func uploadImageIfNeeded(_ imageData: Data?, token: String) async throws -> UploadedFile? {
        guard let imageData else { return nil }
        return try await plantService.uploadPhoto(imageData, token: token)
    }
    
    private func markWateringAsPending(plantIndex: Int) {
        let wateredAt = Date()
        let localLogId = -Int(wateredAt.timeIntervalSince1970 * 1000)
        let note = "Watered today".localized
        let plantId = plants[plantIndex].id
        let pendingLog = WateringLog(id: localLogId, wateredAt: wateredAt, note: note, isPending: true)
        let pendingAction = PendingWateringAction(plantId: plantId, localLogId: localLogId, wateredAt: wateredAt, note: note)
        
        plants[plantIndex].lastWateredAt = wateredAt
        plants[plantIndex].wateringHistory.insert(pendingLog, at: 0)
        selectedPlantHistory[plantId, default: []].insert(pendingLog, at: 0)
        pendingWateringActions.append(pendingAction)
        savePendingWateringActions()
        savePlantsToCache()
        status = .success
    }
    
    private func mergePendingWateringActionsIntoPlants() {
        for action in pendingWateringActions {
            guard let index = plants.firstIndex(where: { $0.id == action.plantId }) else { continue }
            let alreadyExists = plants[index].wateringHistory.contains { $0.id == action.localLogId }
            if !alreadyExists {
                let pendingLog = WateringLog(id: action.localLogId, wateredAt: action.wateredAt, note: action.note, isPending: true)
                plants[index].wateringHistory.insert(pendingLog, at: 0)
                plants[index].lastWateredAt = max(plants[index].lastWateredAt, action.wateredAt)
            }
        }
    }
    
    private func replacePendingWateringLog(action: PendingWateringAction, syncedLog: WateringLog) {
        if let plantIndex = plants.firstIndex(where: { $0.id == action.plantId }) {
            plants[plantIndex].wateringHistory.removeAll { $0.id == action.localLogId }
            plants[plantIndex].wateringHistory.insert(syncedLog, at: 0)
            plants[plantIndex].lastWateredAt = syncedLog.wateredAt
        }
        
        selectedPlantHistory[action.plantId]?.removeAll { $0.id == action.localLogId }
        selectedPlantHistory[action.plantId, default: []].insert(syncedLog, at: 0)
    }
    
    private func incrementPendingRetryCount(actionId: UUID) {
        guard let index = pendingWateringActions.firstIndex(where: { $0.id == actionId }) else { return }
        pendingWateringActions[index].retryCount += 1
    }
    
    private func savePlantsToCache() {
        guard let data = try? JSONEncoder().encode(plants) else { return }
        UserDefaults.standard.set(data, forKey: cachedPlantsKey)
    }
    
    private func savePendingWateringActions() {
        guard let data = try? JSONEncoder().encode(pendingWateringActions) else { return }
        UserDefaults.standard.set(data, forKey: pendingWateringActionsKey)
    }
    
    private static func loadCachedPlants() -> [Plant] {
        guard let data = UserDefaults.standard.data(forKey: "cachedPlants") else { return [] }
        return (try? JSONDecoder().decode([Plant].self, from: data)) ?? []
    }
    
    private static func loadPendingWateringActions() -> [PendingWateringAction] {
        guard let data = UserDefaults.standard.data(forKey: "pendingWateringActions") else { return [] }
        return (try? JSONDecoder().decode([PendingWateringAction].self, from: data)) ?? []
    }
}
