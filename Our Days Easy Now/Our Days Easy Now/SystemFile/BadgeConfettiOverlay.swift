// BadgeConfettiOverlay.swift
// Our Days: Easy Now
// Confetti animation when badge is unlocked

import SwiftUI

struct BadgeConfettiOverlay: View {
    let badge: NestBadge
    @State private var burstRadius: CGFloat = 0

    private let particleCount = 24
    private let colors: [Color] = [
        NestPalette.hearthGold,
        NestPalette.candleAmber,
        NestPalette.bondSpark,
        NestPalette.harmonyMoss,
        NestPalette.streakEmber,
    ]

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                ForEach(0..<particleCount, id: \.self) { i in
                    let angle = Double(i) * (360.0 / Double(particleCount)) * .pi / 180
                    let size = CGFloat([4, 6, 8, 10][i % 4])
                    Circle()
                        .fill(colors[i % colors.count])
                        .frame(width: size, height: size)
                        .position(
                            x: center.x + cos(angle) * burstRadius,
                            y: center.y + sin(angle) * burstRadius
                        )
                        .opacity(burstRadius > 100 ? 0 : 0.9)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                burstRadius = 180
            }
        }
    }
}
