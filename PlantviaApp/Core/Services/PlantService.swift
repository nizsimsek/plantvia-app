//
//  PlantService.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 29.05.2026.
//

import Foundation

protocol PlantServiceProtocol {
    func fetchPlants(token: String) async throws -> [Plant]
    func createPlant(_ request: PlantMutationRequest, token: String) async throws -> Plant
    func updatePlant(plantId: Int, _ request: PlantMutationRequest, token: String) async throws -> Plant
    func deletePlant(plantId: Int, token: String) async throws
    func waterPlant(plantId: Int, wateredAt: Date, note: String, token: String) async throws -> WateringLog
    func fetchWateringHistory(plantId: Int, token: String) async throws -> [WateringLog]
    func uploadPhoto(_ imageData: Data, token: String) async throws -> UploadedFile
}

final class PlantService: PlantServiceProtocol {
    func fetchPlants(token: String) async throws -> [Plant] {
        let envelope: APIEnvelope<[Plant]> = try await APIClient.shared.request("plants", token: token)
        return envelope.data ?? []
    }
    
    func createPlant(_ request: PlantMutationRequest, token: String) async throws -> Plant {
        let envelope: APIEnvelope<Plant> = try await APIClient.shared.request("plants", method: "POST", body: request, token: token)
        guard let plant = envelope.data else { throw APIError.server(envelope.message) }
        return plant
    }
    
    func updatePlant(plantId: Int, _ request: PlantMutationRequest, token: String) async throws -> Plant {
        let envelope: APIEnvelope<Plant> = try await APIClient.shared.request("plants/\(plantId)", method: "PUT", body: request, token: token)
        guard let plant = envelope.data else { throw APIError.server(envelope.message) }
        return plant
    }
    
    func deletePlant(plantId: Int, token: String) async throws {
        let _: APIEnvelope<EmptyAPIData> = try await APIClient.shared.request("plants/\(plantId)", method: "DELETE", token: token)
    }
    
    func waterPlant(plantId: Int, wateredAt: Date = Date(), note: String, token: String) async throws -> WateringLog {
        let request = WateringLogRequest(plantId: plantId, wateredAt: ISO8601DateFormatter().string(from: wateredAt), note: note)
        let envelope: APIEnvelope<WateringLog> = try await APIClient.shared.request("watering/logs", method: "POST", body: request, token: token)
        guard let log = envelope.data else { throw APIError.server(envelope.message) }
        return log
    }
    
    func fetchWateringHistory(plantId: Int, token: String) async throws -> [WateringLog] {
        let envelope: APIEnvelope<[WateringLog]> = try await APIClient.shared.request("watering/logs/\(plantId)", token: token)
        return envelope.data ?? []
    }
    
    func uploadPhoto(_ imageData: Data, token: String) async throws -> UploadedFile {
        let envelope: APIEnvelope<UploadedFile> = try await APIClient.shared.uploadImage("uploads/photo", imageData: imageData, token: token)
        guard let file = envelope.data else { throw APIError.server(envelope.message) }
        return file
    }
}

struct PlantMutationRequest: Encodable {
    let name: String
    let species: String
    let imageUrl: String?
    let location: String
    let wateringFrequencyDays: Int
    let reminderTime: String
    let lastWateredAt: String
    let notes: String
}

struct WateringLogRequest: Encodable {
    let plantId: Int
    let wateredAt: String
    let note: String
}

extension DateFormatter {
    static let plantviaHourMinute: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
