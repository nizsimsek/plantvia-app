//
//  PlantImageView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 29.05.2026.
//

import SwiftUI

struct PlantImageView: View {
    let plant: Plant
    var size: CGFloat
    var cornerRadius: CGFloat = 16
    
    var body: some View {
        Group {
            if let imageUrl = plant.imageUrl,
               let url = URL(string: imageUrl, relativeTo: APIClient.shared.baseURL.deletingLastPathComponent()) {
                AsyncImage(url: url.absoluteURL) { phase in
                    switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            fallbackIcon
                    }
                }
            } else {
                fallbackIcon
            }
        }
        .frame(width: size, height: size)
        .background(
            LinearGradient(
                colors: [.plantviaMint.opacity(0.55), .plantviaSky.opacity(0.20), .plantviaLeaf.opacity(0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        )
    }
    
    private var fallbackIcon: some View {
        Image(systemName: plant.imageName)
            .font(.system(size: size * 0.45))
            .foregroundStyle(Color.plantviaPrimary)
    }
}
