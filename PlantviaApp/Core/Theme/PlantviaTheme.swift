//
//  PlantviaTheme.swift
//  PlantviaApp
//
//  Created by Nizamettin Şimşek on 28.05.2026.
//

import SwiftUI

extension Color {
    static let plantviaPrimary = Color(red: 0.10, green: 0.55, blue: 0.36)
    static let plantviaForest = Color(red: 0.04, green: 0.24, blue: 0.17)
    static let plantviaLeaf = Color(red: 0.29, green: 0.75, blue: 0.45)
    static let plantviaMint = Color(red: 0.66, green: 0.94, blue: 0.78)
    static let plantviaSky = Color(red: 0.51, green: 0.79, blue: 0.93)
    static let plantviaLavender = Color(red: 0.68, green: 0.64, blue: 0.96)
    static let plantviaWarning = Color(red: 0.95, green: 0.61, blue: 0.25)
    static let plantviaDanger = Color(red: 0.89, green: 0.28, blue: 0.24)
    static let plantviaCard = Color(.secondarySystemGroupedBackground)
    static let plantviaElevatedCard = Color(.systemBackground)
}

enum PlantviaSpacing {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 34
}

struct PremiumGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                LinearGradient(
                    colors: backgroundColors,
                    startPoint: UnitPoint(x: 0.18 + sin(phase / 9) * 0.08, y: 0.02),
                    endPoint: UnitPoint(x: 0.92, y: 0.92 + cos(phase / 11) * 0.08)
                )
                
                AngularGradient(
                    colors: [
                        .plantviaMint.opacity(colorScheme == .dark ? 0.18 : 0.30),
                        .plantviaSky.opacity(colorScheme == .dark ? 0.12 : 0.22),
                        .plantviaLavender.opacity(colorScheme == .dark ? 0.10 : 0.18),
                        .clear,
                        .plantviaMint.opacity(colorScheme == .dark ? 0.18 : 0.30)
                    ],
                    center: .topLeading,
                    angle: .degrees(phase.truncatingRemainder(dividingBy: 360))
                )
                .blur(radius: 42)
                .opacity(0.72)
            }
        }
        .ignoresSafeArea()
    }
    
    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                .plantviaForest,
                Color(red: 0.04, green: 0.12, blue: 0.13),
                Color(.systemBackground)
            ]
        }
        
        return [
            .plantviaMint.opacity(0.72),
            .plantviaSky.opacity(0.36),
            .plantviaLavender.opacity(0.16),
            Color(.systemBackground)
        ]
    }
}

struct PlantviaSurface<Content: View>: View {
    var cornerRadius: CGFloat = 24
    var content: Content
    
    init(cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(PlantviaSpacing.md)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 10)
    }
}

struct PlantviaChip: View {
    let title: String
    let icon: String?
    var tint: Color = .plantviaPrimary
    var isSelected = false
    
    var body: some View {
        HStack(spacing: 7) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
            }
            Text(title)
                .font(.caption.weight(.bold))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .foregroundStyle(isSelected ? .white : tint)
        .background(isSelected ? tint : tint.opacity(0.12))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(tint.opacity(isSelected ? 0 : 0.18), lineWidth: 1)
        )
    }
}

struct PressableScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

struct PlantviaTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color.plantviaElevatedCard.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.20), lineWidth: 1)
            )
    }
}

extension View {
    func plantviaField() -> some View {
        modifier(PlantviaTextFieldStyle())
    }

    func dismissKeyboardOnTap() -> some View {
        simultaneousGesture(TapGesture().onEnded {
#if canImport(UIKit)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
        })
    }
}

extension PlantStatus {
    var tintColor: Color {
        switch self {
            case .healthy: return .plantviaPrimary
            case .needsWatering: return .plantviaSky
            case .overdue: return .plantviaDanger
        }
    }
}
