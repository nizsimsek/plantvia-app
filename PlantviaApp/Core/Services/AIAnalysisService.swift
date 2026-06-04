//
//  AIAnalysisService.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation
import SwiftUI

protocol AIAnalysisServiceProtocol {
    func performPlantAnalysis(question: String, plantId: Int?, imageData: Data?, token: String?) async throws -> AIAnalysisAnswer
}

final class AIAnalysisService: AIAnalysisServiceProtocol {
    func performPlantAnalysis(question: String, plantId: Int? = nil, imageData: Data? = nil, token: String? = nil) async throws -> AIAnalysisAnswer {
        guard let token else { throw AIError.clearMessage("AI analysis requires an active session.".localized) }
        
        let envelope: APIEnvelope<AIAnalysisAnswer>
        if let imageData {
            var fields = ["question": question]
            if let plantId {
                fields["plantId"] = String(plantId)
            }
            envelope = try await APIClient.shared.uploadMultipartImage(
                "ai/analyze-plant",
                imageData: imageData,
                fields: fields,
                token: token,
                fallbackMessage: "AI analysis could not be completed.".localized
            )
        } else {
            let request = AIAnalysisRequest(question: question, plantId: plantId)
            envelope = try await APIClient.shared.request("ai/analyze-plant", method: "POST", body: request, token: token)
        }
        
        guard let answer = envelope.data else { throw APIError.server(envelope.message) }
        return answer
    }
}

struct AIAnalysisRequest: Encodable {
    let question: String
    let plantId: Int?
}

enum AIError: LocalizedError {
    case clearMessage(String)
    
    var errorDescription: String? {
        switch self {
            case .clearMessage(let message): return message
        }
    }
}
