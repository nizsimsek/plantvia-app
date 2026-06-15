//
//  PlantRowView.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI

struct PlantRowView: View {
    let plant: Plant
    
    var body: some View {
        HStack(spacing: 12) {
            PlantImageView(plant: plant, size: 56, cornerRadius: 18)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(plant.species) • \(plant.location.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(L10n.format("Next watering: %@", plant.nextWateringDate.appFormatted()))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: plant.status.icon)
                .foregroundStyle(plant.status.tintColor)
                .frame(width: 34, height: 34)
                .background(plant.status.tintColor.opacity(0.12))
                .clipShape(Circle())
        }
        .padding(.vertical, 6)
    }
}
