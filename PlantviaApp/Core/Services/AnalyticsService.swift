//
//  AnalyticsService.swift
//  PlantviaApp
//

import Foundation

// PostHog SDK entegrasyonu için:
// 1. Package.swift veya SPM'e posthog-ios (github.com/PostHog/posthog-ios) ekle
// 2. Aşağıdaki import'u aktif et: import PostHog
// 3. configure() içinde PostHogSDK.shared.setup(...) çağır

protocol AnalyticsServiceProtocol {
    func configure()
    func identify(userId: String, plan: String)
    func track(_ event: AnalyticsEvent)
    func reset()
}

enum AnalyticsEvent {
    // Onboarding
    case onboardingCompleted
    case firstPlantPromptShown
    case firstPlantPromptAccepted
    case firstPlantPromptSkipped

    // Auth
    case signedUp
    case loggedIn
    case loggedOut

    // Plants
    case plantAdded(location: String)
    case plantWatered
    case plantDeleted

    // AI
    case aiAnalysisStarted
    case aiAnalysisCompleted(confidenceLevel: String)
    case aiLimitReached

    // Subscription
    case paywallShown(source: String)
    case purchaseStarted(plan: String)
    case purchaseCompleted(plan: String)
    case purchaseFailed
    case subscriptionRestored

    var name: String {
        switch self {
        case .onboardingCompleted:      return "onboarding_completed"
        case .firstPlantPromptShown:    return "first_plant_prompt_shown"
        case .firstPlantPromptAccepted: return "first_plant_prompt_accepted"
        case .firstPlantPromptSkipped:  return "first_plant_prompt_skipped"
        case .signedUp:                 return "signed_up"
        case .loggedIn:                 return "logged_in"
        case .loggedOut:                return "logged_out"
        case .plantAdded:               return "plant_added"
        case .plantWatered:             return "plant_watered"
        case .plantDeleted:             return "plant_deleted"
        case .aiAnalysisStarted:        return "ai_analysis_started"
        case .aiAnalysisCompleted:      return "ai_analysis_completed"
        case .aiLimitReached:           return "ai_limit_reached"
        case .paywallShown:             return "paywall_shown"
        case .purchaseStarted:          return "purchase_started"
        case .purchaseCompleted:        return "purchase_completed"
        case .purchaseFailed:           return "purchase_failed"
        case .subscriptionRestored:     return "subscription_restored"
        }
    }

    var properties: [String: Any] {
        switch self {
        case .plantAdded(let location):
            return ["location": location]
        case .aiAnalysisCompleted(let level):
            return ["confidence_level": level]
        case .paywallShown(let source):
            return ["source": source]
        case .purchaseStarted(let plan), .purchaseCompleted(let plan):
            return ["plan": plan]
        default:
            return [:]
        }
    }
}

// MARK: - Live Implementation (PostHog)

final class PostHogAnalyticsService: AnalyticsServiceProtocol {
    private let apiKey: String
    private let host: String

    init(apiKey: String, host: String = "https://eu.posthog.com") {
        self.apiKey = apiKey
        self.host = host
    }

    func configure() {
        // TODO: Uncomment after adding posthog-ios SPM dependency
        // let config = PostHogConfig(apiKey: apiKey, host: host)
        // PostHogSDK.shared.setup(config)
    }

    func identify(userId: String, plan: String) {
        // PostHogSDK.shared.identify(userId, userProperties: ["plan": plan])
    }

    func track(_ event: AnalyticsEvent) {
        // PostHogSDK.shared.capture(event.name, properties: event.properties)
    }

    func reset() {
        // PostHogSDK.shared.reset()
    }
}

// MARK: - No-op (testing / preview)

final class NoOpAnalyticsService: AnalyticsServiceProtocol {
    func configure() {}
    func identify(userId: String, plan: String) {}
    func track(_ event: AnalyticsEvent) {}
    func reset() {}
}
