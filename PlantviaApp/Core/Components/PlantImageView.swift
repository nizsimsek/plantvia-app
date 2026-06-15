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
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.plantviaMint.opacity(0.55), .plantviaSky.opacity(0.20), .plantviaLeaf.opacity(0.14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                if let url = APIClient.shared.imageURL(forPath: plant.imageUrl) {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            fallbackIcon
                        }
                    }
                    .id(plant.imageUrl)
                } else {
                    fallbackIcon
                }
            }
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
