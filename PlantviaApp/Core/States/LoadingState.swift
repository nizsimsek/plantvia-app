//
//  LoadingState.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation

enum LoadingState: Equatable {
    case idle
    case loading
    case success
    case failure(String)
    
    var isLoading: Bool {
        self == .loading
    }
    
    var errorMessage: String? {
        if case .failure(let message) = self { return message }
        return nil
    }
}

