//
//  Models.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: Int
    var nickname: String
    var email: String
    var plan: String?
    var language: String?
}

struct Plant: Identifiable, Codable, Equatable {
    let id: Int
    var name: String
    var species: String
    var imageName: String
    var imageUrl: String?
    var location: PlantLocation
    var wateringFrequencyDays: Int
    var reminderTime: String?
    var lastWateredAt: Date
    var notes: String
    var wateringHistory: [WateringLog]
    
    var nextWateringDate: Date {
        Calendar.current.date(
            byAdding: .day,
            value: wateringFrequencyDays,
            to: lastWateredAt
        ) ?? lastWateredAt
    }
    
    var status: PlantStatus {
        let today = Calendar.current.startOfDay(for: Date())
        let nextWateringDay = Calendar.current.startOfDay(for: nextWateringDate)
        
        if nextWateringDay < today {
            return .overdue
        }
        
        if Calendar.current.isDate(nextWateringDay, inSameDayAs: today) {
            return .needsWatering
        }
        
        return .healthy
    }
    
    init(id: Int, name: String, species: String, imageName: String = "leaf.fill", imageUrl: String? = nil, location: PlantLocation, wateringFrequencyDays: Int, reminderTime: String? = nil, lastWateredAt: Date, notes: String, wateringHistory: [WateringLog] = []) {
        self.id = id
        self.name = name
        self.species = species
        self.imageName = imageName
        self.imageUrl = imageUrl
        self.location = location
        self.wateringFrequencyDays = wateringFrequencyDays
        self.reminderTime = reminderTime
        self.lastWateredAt = lastWateredAt
        self.notes = notes
        self.wateringHistory = wateringHistory
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case species
        case imageName
        case imageUrl
        case location
        case wateringFrequencyDays
        case reminderTime
        case lastWateredAt
        case notes
        case wateringHistory
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        species = try container.decodeIfPresent(String.self, forKey: .species) ?? ""
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName) ?? "leaf.fill"
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        let rawLocation = try container.decodeIfPresent(String.self, forKey: .location) ?? PlantLocation.salon.rawValue
        location = PlantLocation.fromBackendValue(rawLocation)
        wateringFrequencyDays = try container.decode(Int.self, forKey: .wateringFrequencyDays)
        reminderTime = try container.decodeIfPresent(String.self, forKey: .reminderTime)
        lastWateredAt = try container.decode(Date.self, forKey: .lastWateredAt)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        wateringHistory = try container.decodeIfPresent([WateringLog].self, forKey: .wateringHistory) ?? []
    }
}

struct WateringLog: Identifiable, Codable, Equatable {
    let id: Int
    let wateredAt: Date
    let note: String
    var isPending: Bool
    
    init(id: Int = 0, wateredAt: Date, note: String, isPending: Bool = false) {
        self.id = id
        self.wateredAt = wateredAt
        self.note = note
        self.isPending = isPending
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case wateredAt
        case note
        case isPending
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        wateredAt = try container.decode(Date.self, forKey: .wateredAt)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        isPending = try container.decodeIfPresent(Bool.self, forKey: .isPending) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(wateredAt, forKey: .wateredAt)
        try container.encode(note, forKey: .note)
        try container.encode(isPending, forKey: .isPending)
    }
}

struct PendingWateringAction: Identifiable, Codable, Equatable {
    let id: UUID
    let plantId: Int
    let localLogId: Int
    let wateredAt: Date
    let note: String
    var retryCount: Int
    
    init(id: UUID = UUID(), plantId: Int, localLogId: Int, wateredAt: Date, note: String, retryCount: Int = 0) {
        self.id = id
        self.plantId = plantId
        self.localLogId = localLogId
        self.wateredAt = wateredAt
        self.note = note
        self.retryCount = retryCount
    }
}

enum PlantLocation: String, CaseIterable, Codable, Identifiable {
    case salon = "Living Room"
    case kitchen = "Kitchen"
    case balcony = "Balcony"
    case bedRoom = "Bedroom"
    case workRoom = "Office"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue.localized }
    
    static func fromBackendValue(_ value: String) -> PlantLocation {
        if let location = PlantLocation(rawValue: value) { return location }
        switch value {
            case "Salon": return .salon
            case "Mutfak": return .kitchen
            case "Balkon": return .balcony
            case "Yatak Odası": return .bedRoom
            case "Çalışma Odası": return .workRoom
            default: return .salon
        }
    }
}

enum PlantStatus: String, Codable {
    case healthy = "Healthy"
    case needsWatering = "Needs watering"
    case overdue = "Overdue"
    
    var displayName: String { rawValue.localized }
    
    var icon: String {
        switch self {
            case .healthy: return "checkmark.seal.fill"
            case .needsWatering: return "drop.fill"
            case .overdue: return "exclamationmark.triangle.fill"
        }
    }
}

struct AIAnalysisAnswer: Codable {
    let answer: String
    let suggestions: [String]
    let confidenceLevel: String
    let warning: String
    let remaining: Int?
}

struct AIUsageStatus: Codable {
    let used: Int
    let remaining: Int
    let limit: Int
}

struct PagedResponse<T: Codable>: Codable {
    let items: [T]
    let pagination: PaginationMeta
}

struct PaginationMeta: Codable {
    let total: Int
    let limit: Int
    let offset: Int
    let hasMore: Bool
}

struct AuthSession: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

struct UploadedFile: Codable {
    let filename: String
    let originalName: String?
    let size: Int
    let url: String
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let fromTheUser: Bool
    let date = Date()
}

enum PremiumPlan: String, CaseIterable, Identifiable {
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var id: String { rawValue }
    var displayName: String { rawValue.localized }
    var price: String { self == .monthly ? "₺79,99" : "₺599,99" }
    
    var revenueCatProductId: String {
        let environment = AppEnvironment.shared
        switch self {
            case .monthly:
                return environment.usesRevenueCatTestStore ? environment.revenueCatTestMonthlyProductId : environment.revenueCatMonthlyProductId
            case .yearly:
                return environment.usesRevenueCatTestStore ? environment.revenueCatTestYearlyProductId : environment.revenueCatYearlyProductId
        }
    }
}
