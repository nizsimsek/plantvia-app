//
//  AdsService.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import Foundation
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif
#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif
#if canImport(UIKit)
import UIKit
#endif

protocol AdsServiceProtocol {
    var bannerAdUnitId: String { get }
    var interstitialAdUnitId: String { get }
    func configureMobileAds()
    func prepareAdsForCurrentUser(isPremiumActive: Bool) async
    func prepareInterstitial()
    func showInterstitialIfNeeded(isPremiumActive: Bool)
    func canShowInterstitial(isPremiumActive: Bool) -> Bool
}

final class AdsService: AdsServiceProtocol {
#if canImport(GoogleMobileAds)
    private var interstitialAd: InterstitialAd?
#endif
    private var didStartMobileAds = false
    
    var bannerAdUnitId: String {
#if DEBUG
        AppEnvironment.shared.admobDebugBannerAdUnitId
#else
        AppEnvironment.shared.admobBannerAdUnitId
#endif
    }
    
    var interstitialAdUnitId: String {
        AppEnvironment.shared.admobInterstitialAdUnitId
    }
    
    func configureMobileAds() {}
    
    func prepareAdsForCurrentUser(isPremiumActive: Bool) async {
        guard !isPremiumActive else { return }
        await requestConsentAndTrackingPermissionIfNeeded()
        startMobileAdsIfNeeded()
        prepareInterstitial()
    }
    
    private func startMobileAdsIfNeeded() {
        guard !didStartMobileAds else { return }
        didStartMobileAds = true
#if canImport(GoogleMobileAds)
        MobileAds.shared.start(completionHandler: nil)
#endif
    }
    
    @MainActor
    private func requestConsentAndTrackingPermissionIfNeeded() async {
#if canImport(UserMessagingPlatform) && canImport(UIKit)
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false
        
        await withCheckedContinuation { continuation in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { _ in
                guard let rootViewController = UIApplication.shared.plantviaRootViewController else {
                    continuation.resume()
                    return
                }
                
                ConsentForm.loadAndPresentIfRequired(from: rootViewController) { _ in
                    continuation.resume()
                }
            }
        }
#endif
        
#if canImport(AppTrackingTransparency)
        if #available(iOS 14, *), ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
#endif
    }
    
    func prepareInterstitial() {
#if canImport(GoogleMobileAds)
        InterstitialAd.load(with: interstitialAdUnitId, request: GoogleMobileAds.Request()) { [weak self] ad, error in
            guard error == nil else {
                self?.interstitialAd = nil
                return
            }
            self?.interstitialAd = ad
        }
#endif
    }
    
    func showInterstitialIfNeeded(isPremiumActive: Bool) {
        guard canShowInterstitial(isPremiumActive: isPremiumActive) else { return }
#if canImport(GoogleMobileAds) && canImport(UIKit)
        guard let rootViewController = UIApplication.shared.plantviaRootViewController else { return }
        interstitialAd?.present(from: rootViewController)
        interstitialAd = nil
        prepareInterstitial()
#endif
    }
    
    func canShowInterstitial(isPremiumActive: Bool) -> Bool {
        !isPremiumActive
    }
}

#if canImport(UIKit)
private extension UIApplication {
    var plantviaRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
#endif
