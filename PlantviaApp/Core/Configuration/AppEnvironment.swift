//
//  AppEnvironment.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 31.05.2026.
//

import Foundation

struct AppEnvironment {
    static let shared = AppEnvironment()
    
    let apiBaseURL: URL
    let admobBannerAdUnitId: String
    let admobDebugBannerAdUnitId: String
    let admobInterstitialAdUnitId: String
    let revenueCatAPIKey: String
    let revenueCatEntitlementId: String
    let revenueCatOfferingId: String
    let revenueCatMonthlyProductId: String
    let revenueCatYearlyProductId: String
    let revenueCatTestMonthlyProductId: String
    let revenueCatTestYearlyProductId: String
    let sentryDsn: String?

    var usesRevenueCatTestStore: Bool {
        revenueCatAPIKey.hasPrefix("test_")
    }
    
    private init(bundle: Bundle = .main) {
        apiBaseURL = Self.urlValue(
            forKey: "PLANTVIA_API_BASE_URL",
            bundle: bundle
        )
        
        admobBannerAdUnitId = Self.stringValue(
            forKey: "PLANTVIA_ADMOB_BANNER_AD_UNIT_ID",
            bundle: bundle
        )
        
        admobDebugBannerAdUnitId = Self.stringValue(
            forKey: "PLANTVIA_ADMOB_DEBUG_BANNER_AD_UNIT_ID",
            bundle: bundle
        )
        
        admobInterstitialAdUnitId = Self.stringValue(
            forKey: "PLANTVIA_ADMOB_INTERSTITIAL_AD_UNIT_ID",
            bundle: bundle
        )
        
        revenueCatAPIKey = Self.stringValue(
            forKey: "PLANTVIA_REVENUECAT_API_KEY",
            bundle: bundle
        )
        
        revenueCatEntitlementId = Self.stringValue(
            forKey: "PLANTVIA_REVENUECAT_ENTITLEMENT_ID",
            bundle: bundle
        )
        
        revenueCatOfferingId = Self.stringValue(
            forKey: "PLANTVIA_REVENUECAT_OFFERING_ID",
            bundle: bundle
        )
        
        revenueCatMonthlyProductId = Self.stringValue(
            forKey: "PLANTVIA_REVENUECAT_MONTHLY_PRODUCT_ID",
            bundle: bundle
        )
        
        revenueCatYearlyProductId = Self.stringValue(
            forKey: "PLANTVIA_REVENUECAT_YEARLY_PRODUCT_ID",
            bundle: bundle
        )
        
        revenueCatTestMonthlyProductId = Self.stringValue(
            forKey: "PLANTVIA_REVENUECAT_TEST_MONTHLY_PRODUCT_ID",
            bundle: bundle
        )
        
        revenueCatTestYearlyProductId = Self.stringValue(
            forKey: "PLANTVIA_REVENUECAT_TEST_YEARLY_PRODUCT_ID",
            bundle: bundle
        )
        sentryDsn = bundle.object(forInfoDictionaryKey: "PLANTVIA_SENTRY_DSN") as? String
    }
    
    private static func stringValue(forKey key: String, bundle: Bundle) -> String {
        guard let value = bundle.object(forInfoDictionaryKey: key) as? String,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            preconditionFailure("\(key) Info.plist içinde tanımlı olmalı.")
        }
        return value
    }
    
    private static func urlValue(forKey key: String, bundle: Bundle) -> URL {
        let value = stringValue(forKey: key, bundle: bundle)
        guard let url = URL(string: value) else {
            preconditionFailure("\(key) Info.plist içinde geçerli bir URL olmalı.")
        }
        return url
    }
}
