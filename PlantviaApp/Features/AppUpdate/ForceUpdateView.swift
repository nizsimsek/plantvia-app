//
//  ForceUpdateView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 29.05.2026.
//

import SwiftUI

struct ForceUpdateView: View {
    let config: AppConfig
    
    var body: some View {
        ZStack {
            PremiumGradientBackground()
            VStack(spacing: 22) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 68, weight: .semibold))
                    .foregroundStyle(Color.plantviaPrimary)
                
                VStack(spacing: 10) {
                    Text("Update required".localized)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    
                    Text(config.message.localized)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text(L10n.format("Minimum supported version: %@", config.minimumSupportedVersion))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                
                Link(destination: URL(string: config.appStoreUrl)!) {
                    Label("Update now".localized, systemImage: "arrow.up.forward.app.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .foregroundStyle(.white)
                        .background(Color.plantviaPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding(24)
        }
    }
}
