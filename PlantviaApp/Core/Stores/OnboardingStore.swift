//
//  OnboardingStore.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation
import Combine

@MainActor
final class OnboardingStore: ObservableObject {
    @Published private(set) var completed: Bool
    
    private let key = "onboardingCompleted"
    
    init() {
        completed = UserDefaults.standard.bool(forKey: key)
    }
    
    func complete() {
        completed = true
        UserDefaults.standard.set(true, forKey: key)
    }
}

