//
//  SubscriptionStore.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation
import Combine

@MainActor
final class SubscriptionStore: ObservableObject {
    @Published private(set) var isPremiumActive: Bool = false
    @Published private(set) var status: LoadingState = .idle
    @Published private(set) var activeEntitlements: [String] = []
    @Published private(set) var revenueCatAppUserId: String?
    @Published private(set) var planOptions: [RevenueCatPlanOption] = []
    
    private let revenueCatService: RevenueCatServiceProtocol
    
    init(revenueCatService: RevenueCatServiceProtocol) {
        self.revenueCatService = revenueCatService
    }
    
    func configureRevenueCat() {
        revenueCatService.configure()
    }
    
    func identifyRevenueCatUser(_ user: User?) async {
        do {
            let customerState = try await revenueCatService.identifyUser(user)
            applyCustomerState(customerState)
        } catch {
            status = .failure(error.localizedDescription)
        }
    }
    
    func refreshSubscriptionStatus(token: String?) async -> User? {
        var backendUser: User?
        var backendPremiumIsActive = false
        
        guard let token else {
            await refreshRevenueCatCustomerInfo()
            return nil
        }
        
        do {
            let subscriptionStatus = try await revenueCatService.fetchSubscriptionStatus(token: token)
            backendPremiumIsActive = subscriptionStatus.plan == "premium"
            backendUser = subscriptionStatus.user
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
        
        isPremiumActive = backendPremiumIsActive
        
        return backendUser
    }
    
    func syncWithUserPlan(_ plan: String?) {
        isPremiumActive = plan == "premium"
    }
    
    func buy(plan: PremiumPlan, token: String?) async -> User? {
        status = .loading
        do {
            let customerState = try await revenueCatService.buy(plan: plan)
            applyCustomerState(customerState)
            let syncedUser = await syncRevenueCatStatusWithBackendIfPossible(token: token)
            status = .success
            return syncedUser
        } catch {
            if isPurchaseCancelled(error) {
#if DEBUG
                print("RevenueCat purchase cancelled: \(error.localizedDescription)")
#endif
                status = .failure("Purchase could not be completed. Please try again.".localized)
                return nil
            }
            
            status = .failure(userFriendlyPurchaseError(error))
            return nil
        }
    }
    
    func loadPlanOptions() async {
        status = .loading
        do {
            planOptions = try await revenueCatService.fetchPlanOptions()
            status = .success
        } catch {
            planOptions = []
            status = .failure(error.localizedDescription)
        }
    }
    
    func restorePurchases(token: String?) async -> User? {
        status = .loading
        do {
            let customerState = try await revenueCatService.restorePurchases()
            applyCustomerState(customerState)
            let syncedUser = await syncRevenueCatStatusWithBackendIfPossible(token: token)
            status = .success
            return syncedUser
        } catch {
            if isPurchaseCancelled(error) {
#if DEBUG
                print("RevenueCat restore cancelled: \(error.localizedDescription)")
#endif
                status = .failure("Purchases could not be restored. Please try again.".localized)
                return nil
            }
            
            status = .failure(userFriendlyRestoreError(error))
            return nil
        }
    }
    
    func refreshRevenueCatCustomerInfo() async {
        do {
            let customerState = try await revenueCatService.refreshCustomerInfo()
            applyCustomerState(customerState)
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }
    
    func syncSubscriptionWithBackend(token: String?) async -> User? {
        await syncRevenueCatStatusWithBackendIfPossible(token: token)
    }
    
    private func applyCustomerState(_ customerState: RevenueCatCustomerState, backendPremiumIsActive: Bool = false) {
        isPremiumActive = customerState.isPremiumActive || backendPremiumIsActive
        activeEntitlements = customerState.activeEntitlements
        revenueCatAppUserId = customerState.appUserId
    }
    
    private func syncRevenueCatStatusWithBackendIfPossible(token: String?) async -> User? {
        guard let token else { return nil }
        
        do {
            let subscriptionStatus = try await revenueCatService.syncSubscriptionWithBackend(token: token)
            isPremiumActive = subscriptionStatus.plan == "premium"
            return subscriptionStatus.user
        } catch {
            status = .failure(error.localizedDescription)
            return nil
        }
    }
    
    private func userFriendlyPurchaseError(_ error: Error) -> String {
#if DEBUG
        if let serviceError = error as? RevenueCatServiceError {
            print("RevenueCat purchase error: \(serviceError)")
        } else {
            print("RevenueCat purchase error: \(error.localizedDescription)")
        }
#endif
        return "Purchase could not be completed. Please try again.".localized
    }
    
    private func userFriendlyRestoreError(_ error: Error) -> String {
#if DEBUG
        print("RevenueCat restore error: \(error.localizedDescription)")
#endif
        return "Purchases could not be restored. Please try again.".localized
    }
    
    private func isPurchaseCancelled(_ error: Error) -> Bool {
        if let serviceError = error as? RevenueCatServiceError {
            if case .purchaseCancelled = serviceError {
                return true
            }
        }
        
        let message = error.localizedDescription.lowercased()
        return message.contains("cancel")
    }
}
