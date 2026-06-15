//
//  RevenueCatService.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation
#if canImport(RevenueCat)
import RevenueCat
#endif

protocol RevenueCatServiceProtocol {
    func configure()
    func identifyUser(_ user: User?) async throws -> RevenueCatCustomerState
    func fetchSubscriptionStatus(token: String) async throws -> SubscriptionStatusResponse
    func syncSubscriptionWithBackend(token: String) async throws -> SubscriptionStatusResponse
    func refreshCustomerInfo() async throws -> RevenueCatCustomerState
    func fetchPlanOptions() async throws -> [RevenueCatPlanOption]
    func buy(plan: PremiumPlan) async throws -> RevenueCatCustomerState
    func restorePurchases() async throws -> RevenueCatCustomerState
}

struct RevenueCatPlanOption: Equatable, Identifiable {
    let plan: PremiumPlan
    let productId: String
    let packageId: String
    let localizedPrice: String
    let localizedIntroductoryPrice: String?
    let hasTrial: Bool
    let trialDays: Int?

    var id: String { productId }
}

struct RevenueCatCustomerState: Equatable {
    let isPremiumActive: Bool
    let activeEntitlements: [String]
    let appUserId: String?
}

enum RevenueCatServiceError: LocalizedError {
    case sdkNotLinked
    case offeringNotFound(String)
    case packageNotFound(productId: String, availablePackages: [String])
    case purchaseCancelled
    case purchaseFailed(debugMessage: String)
    
    var errorDescription: String? {
        switch self {
            case .sdkNotLinked:
                return "RevenueCat SDK is not linked. Please resolve Swift Package dependencies in Xcode."
            case .offeringNotFound(let offeringId):
                return "RevenueCat offering could not be found: \(offeringId)"
            case .packageNotFound(let productId, let availablePackages):
                let availableText = availablePackages.isEmpty ? "No packages returned." : availablePackages.joined(separator: ", ")
                return "RevenueCat product could not be found in the offering: \(productId). Available packages: \(availableText)"
            case .purchaseCancelled:
                return "Purchase was cancelled."
            case .purchaseFailed:
                return "Purchase could not be completed. Please try again."
        }
    }
}

final class RevenueCatService: RevenueCatServiceProtocol {
    private let environment: AppEnvironment
    private var isConfigured = false
    
    init(environment: AppEnvironment = .shared) {
        self.environment = environment
    }
    
    func configure() {
        guard !isConfigured else { return }
        isConfigured = true
        
#if canImport(RevenueCat)
#if DEBUG
        Purchases.logLevel = .debug
#else
        Purchases.logLevel = .warn
#endif
        Purchases.configure(withAPIKey: environment.revenueCatAPIKey)
#endif
    }
    
    func identifyUser(_ user: User?) async throws -> RevenueCatCustomerState {
        configure()
#if canImport(RevenueCat)
        if let user {
            let result = try await Purchases.shared.logIn(String(user.id))
            return Self.state(from: result.customerInfo, entitlementId: environment.revenueCatEntitlementId)
        } else if !Purchases.shared.isAnonymous {
            let customerInfo = try await Purchases.shared.logOut()
            return Self.state(from: customerInfo, entitlementId: environment.revenueCatEntitlementId)
        } else {
            return RevenueCatCustomerState(isPremiumActive: false, activeEntitlements: [], appUserId: Purchases.shared.appUserID)
        }
#else
        throw RevenueCatServiceError.sdkNotLinked
#endif
    }
    
    func fetchSubscriptionStatus(token: String) async throws -> SubscriptionStatusResponse {
        let envelope: APIEnvelope<SubscriptionStatusResponse> = try await APIClient.shared.request("subscriptions/status", token: token)
        guard let status = envelope.data else { throw APIError.server(envelope.message) }
        return status
    }
    
    func syncSubscriptionWithBackend(token: String) async throws -> SubscriptionStatusResponse {
        let envelope: APIEnvelope<SubscriptionStatusResponse> = try await APIClient.shared.request("subscriptions/sync-revenuecat", method: "POST", token: token)
        guard let status = envelope.data else { throw APIError.server(envelope.message) }
        return status
    }
    
    func refreshCustomerInfo() async throws -> RevenueCatCustomerState {
        configure()
#if canImport(RevenueCat)
        let customerInfo = try await Purchases.shared.customerInfo()
        return Self.state(from: customerInfo, entitlementId: environment.revenueCatEntitlementId)
#else
        throw RevenueCatServiceError.sdkNotLinked
#endif
    }
    
    func fetchPlanOptions() async throws -> [RevenueCatPlanOption] {
        configure()
#if canImport(RevenueCat)
        let offering = try await currentOffering()
        
        return PremiumPlan.allCases.compactMap { plan in
            guard let package = package(for: plan, in: offering) else { return nil }
            let discount = package.storeProduct.introductoryDiscount
            let hasTrial = discount?.paymentMode == .freeTrial
            let trialDays: Int? = hasTrial ? Self.trialDays(from: discount) : nil
            return RevenueCatPlanOption(
                plan: plan,
                productId: package.storeProduct.productIdentifier,
                packageId: package.identifier,
                localizedPrice: package.localizedPriceString,
                localizedIntroductoryPrice: package.localizedIntroductoryPriceString,
                hasTrial: hasTrial,
                trialDays: trialDays
            )
        }
#else
        throw RevenueCatServiceError.sdkNotLinked
#endif
    }
    
    func buy(plan: PremiumPlan) async throws -> RevenueCatCustomerState {
        configure()
#if canImport(RevenueCat)
        let offering = try await currentOffering()
        guard let package = package(for: plan, in: offering) else {
            throw RevenueCatServiceError.packageNotFound(
                productId: plan.revenueCatProductId,
                availablePackages: packageDebugDescriptions(in: offering)
            )
        }
        
#if DEBUG
        print("RevenueCat purchase diagnostics: offering=\(offering.identifier), package=\(package.identifier), product=\(package.storeProduct.productIdentifier), appUserId=\(Purchases.shared.appUserID)")
#endif
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                throw RevenueCatServiceError.purchaseCancelled
            }
            
            return Self.state(from: result.customerInfo, entitlementId: environment.revenueCatEntitlementId)
        } catch let error as RevenueCatServiceError {
            throw error
        } catch {
            throw RevenueCatServiceError.purchaseFailed(debugMessage: Self.debugDescription(for: error))
        }
#else
        throw RevenueCatServiceError.sdkNotLinked
#endif
    }
    
    func restorePurchases() async throws -> RevenueCatCustomerState {
        configure()
#if canImport(RevenueCat)
        let customerInfo = try await Purchases.shared.restorePurchases()
        return Self.state(from: customerInfo, entitlementId: environment.revenueCatEntitlementId)
#else
        throw RevenueCatServiceError.sdkNotLinked
#endif
    }
}

#if canImport(RevenueCat)
private extension RevenueCatService {
    func currentOffering() async throws -> Offering {
        let offerings = try await Purchases.shared.offerings()
        guard let offering = offerings.offering(identifier: environment.revenueCatOfferingId) ?? offerings.current else {
            throw RevenueCatServiceError.offeringNotFound(environment.revenueCatOfferingId)
        }
        return offering
    }
    
    func package(for plan: PremiumPlan, in offering: Offering) -> Package? {
        offering.availablePackages.first { package in
            package.storeProduct.productIdentifier == plan.revenueCatProductId
            || package.identifier == plan.revenueCatProductId
            || package.matches(plan: plan)
        }
    }
    
    func packageDebugDescriptions(in offering: Offering) -> [String] {
        offering.availablePackages.map { package in
            "\(package.identifier) -> \(package.storeProduct.productIdentifier)"
        }
    }
    
    static func trialDays(from discount: StoreProductDiscount?) -> Int? {
        guard let discount else { return nil }
        let period = discount.subscriptionPeriod
        switch period.unit {
            case .day:   return period.value
            case .week:  return period.value * 7
            case .month: return period.value * 30
            case .year:  return period.value * 365
            @unknown default: return nil
        }
    }

    static func state(from customerInfo: CustomerInfo, entitlementId: String) -> RevenueCatCustomerState {
        RevenueCatCustomerState(
            isPremiumActive: customerInfo.entitlements[entitlementId]?.isActive == true,
            activeEntitlements: Array(customerInfo.entitlements.active.keys),
            appUserId: customerInfo.originalAppUserId
        )
    }
    
    static func debugDescription(for error: Error) -> String {
        let nsError = error as NSError
        let rootError = nsError.userInfo["rc_root_error"] ?? "nil"
        return "domain=\(nsError.domain), code=\(nsError.code), description=\(nsError.localizedDescription), root=\(rootError)"
    }
}

private extension Package {
    func matches(plan: PremiumPlan) -> Bool {
        switch plan {
            case .monthly:
                return packageType == .monthly || identifier == "$rc_monthly" || identifier.caseInsensitiveCompare("monthly") == .orderedSame
            case .yearly:
                return packageType == .annual || identifier == "$rc_annual" || identifier.caseInsensitiveCompare("yearly") == .orderedSame
        }
    }
}
#endif

struct SubscriptionStatusResponse: Decodable {
    let plan: String
    let user: User?
}
