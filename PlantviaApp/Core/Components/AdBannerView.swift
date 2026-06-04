//
//  AdBannerView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI
#if canImport(GoogleMobileAds) && canImport(UIKit)
import GoogleMobileAds
import UIKit
#endif

struct AdBannerView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var connectivityStore: ConnectivityStore
    
    var body: some View {
        if !subscriptionStore.isPremiumActive && connectivityStore.isOnline {
            AdMobBannerContainer(adUnitId: container.adsService.bannerAdUnitId)
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(Color.plantviaCard)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

private struct AdMobBannerContainer: View {
    let adUnitId: String
    
    var body: some View {
#if canImport(GoogleMobileAds) && canImport(UIKit)
        AdMobBannerRepresentable(adUnitId: adUnitId)
#else
        HStack(spacing: 12) {
            Image(systemName: "rectangle.3.group.bubble.left")
                .foregroundStyle(Color.plantviaPrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text("AdMob Banner".localized)
                    .font(.footnote.bold())
                Text("Google Mobile Ads SDK is not linked yet.".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
#endif
    }
}

#if canImport(GoogleMobileAds) && canImport(UIKit)
private struct AdMobBannerRepresentable: UIViewRepresentable {
    let adUnitId: String
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitId
        bannerView.rootViewController = UIApplication.shared.plantviaRootViewController
        bannerView.delegate = context.coordinator
        bannerView.load(GoogleMobileAds.Request())
        return bannerView
    }
    
    func updateUIView(_ bannerView: BannerView, context: Context) {
        bannerView.adUnitID = adUnitId
        bannerView.rootViewController = UIApplication.shared.plantviaRootViewController
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    final class Coordinator: NSObject, BannerViewDelegate {
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("AdMob banner failed: \(error.localizedDescription)")
        }
    }
}

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
