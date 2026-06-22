//
//  Theme.swift
//  Elite
//
//  Centralised colours, gradients and reusable view modifiers that
//  reproduce the iOS 26 "Liquid Glass" look: soft translucent cards,
//  large corner radii, subtle strokes and vivid accent gradients.
//

import SwiftUI

enum Theme {
    // Accent gradient used across buttons and highlights.
    static let accent = LinearGradient(
        colors: [Color(red: 0.36, green: 0.55, blue: 1.0),
                 Color(red: 0.62, green: 0.36, blue: 1.0)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // Deep background gradient (near-black with a blue/purple bloom).
    static let background = LinearGradient(
        colors: [Color(red: 0.04, green: 0.05, blue: 0.10),
                 Color(red: 0.07, green: 0.06, blue: 0.14),
                 Color(red: 0.03, green: 0.03, blue: 0.06)],
        startPoint: .top, endPoint: .bottom
    )

    static let cardFill = Color.white.opacity(0.06)
    static let cardStroke = Color.white.opacity(0.12)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let success = Color(red: 0.30, green: 0.85, blue: 0.55)
    static let telegram = Color(red: 0.16, green: 0.63, blue: 0.92)
}

/// A frosted-glass rounded container, the core building block of the UI.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 26
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Theme.cardFill)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.cardStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    /// Applies the glass card background to any view.
    func glassCard(cornerRadius: CGFloat = 26) -> some View {
        GlassCard(cornerRadius: cornerRadius) { self }
    }
}
