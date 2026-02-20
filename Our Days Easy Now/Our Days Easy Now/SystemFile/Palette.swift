// NestPalette.swift
// Our Days: Easy Now
// Color system — all names follow the family/hearth metaphor

import SwiftUI

// MARK: - Core Palette

enum NestPalette {

    // ── Backgrounds ──

    /// Deep dark base — the night sky of our nest
    static let emberNight = Color(hex: "0D0D12")

    /// Slightly lighter dark surface — cradle in the dark
    static let cradleDark = Color(hex: "16161E")

    /// Card / elevated surface — the warm blanket
    static let blanketCharcoal = Color(hex: "1E1E2A")

    /// Subtle separator / border — moonlit thread
    static let moonThread = Color(hex: "2A2A3A")

    // ── Accents ──

    /// Primary gold accent — the hearth fire glow
    static let hearthGold = Color(hex: "F7D031")

    /// Softer gold for secondary elements — candlelight
    static let candleAmber = Color(hex: "E8B828")

    /// Warm bronze for tertiary highlights — lullaby bronze
    static let lullabyBronze = Color(hex: "C4973B")

    // ── Text ──

    /// Primary text — pure snowfall white
    static let snowfall = Color.white

    /// Secondary text — dusk whisper
    static let duskWhisper = Color(hex: "9494A8")

    /// Tertiary / disabled text — shadow murmur
    static let shadowMurmur = Color(hex: "5C5C72")

    // ── Semantic / Gamification ──

    /// Streak fire — active streak indicator
    static let streakEmber = Color(hex: "FF6B35")

    /// Bond spark — thanks / appreciation glow
    static let bondSpark = Color(hex: "7B68EE")

    /// Harmony green — balance achieved
    static let harmonyMoss = Color(hex: "4ECDC4")

    /// Gentle alert — soft nudge rose
    static let nudgeRose = Color(hex: "E8637A")

    // ── Member Colors (for charts & avatars) ──

    static let kinColors: [Color] = [
        Color(hex: "F7D031"), // gold
        Color(hex: "7B68EE"), // purple
        Color(hex: "4ECDC4"), // teal
        Color(hex: "FF6B35"), // orange
        Color(hex: "E8637A"), // rose
        Color(hex: "45B7D1"), // sky
    ]

    static func kinColor(at index: Int) -> Color {
        kinColors[index % kinColors.count]
    }
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Background Effects

struct EmberNightBackground: View {
    @State private var shimmerPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            NestPalette.emberNight.ignoresSafeArea()

            // Subtle radial glow from top
            RadialGradient(
                gradient: Gradient(colors: [
                    NestPalette.hearthGold.opacity(0.04),
                    Color.clear
                ]),
                center: .topLeading,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Secondary subtle glow from bottom-right
            RadialGradient(
                gradient: Gradient(colors: [
                    NestPalette.bondSpark.opacity(0.03),
                    Color.clear
                ]),
                center: .bottomTrailing,
                startRadius: 30,
                endRadius: 350
            )
            .ignoresSafeArea()

            // Floating particles effect (hidden when Reduce Motion is on)
            if !reduceMotion {
                EmberParticlesView()
                    .ignoresSafeArea()
                    .opacity(0.6)
            }
        }
    }
}

// MARK: - Floating Ember Particles

struct EmberParticlesView: View {
    var body: some View {
        Canvas { context, size in
            let sparks: [(x: CGFloat, y: CGFloat, radius: CGFloat, opacity: Double)] = [
                (0.15, 0.20, 1.8, 0.4),
                (0.72, 0.12, 1.2, 0.3),
                (0.88, 0.35, 2.0, 0.25),
                (0.30, 0.55, 1.5, 0.35),
                (0.60, 0.70, 1.0, 0.2),
                (0.10, 0.80, 1.6, 0.3),
                (0.50, 0.90, 1.3, 0.25),
                (0.82, 0.60, 1.1, 0.2),
                (0.40, 0.15, 0.9, 0.3),
                (0.92, 0.85, 1.4, 0.15),
            ]

            for spark in sparks {
                let point = CGPoint(x: size.width * spark.x, y: size.height * spark.y)
                let rect = CGRect(
                    x: point.x - spark.radius,
                    y: point.y - spark.radius,
                    width: spark.radius * 2,
                    height: spark.radius * 2
                )
                context.opacity = spark.opacity
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(NestPalette.hearthGold)
                )
            }
        }
    }
}

// MARK: - Animated Ember Background (for Splash / Onboarding)

struct AnimatedEmberSky: View {
    @State private var drift: CGFloat = 0

    var body: some View {
        ZStack {
            NestPalette.emberNight.ignoresSafeArea()

            // Animated warm glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            NestPalette.hearthGold.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -80 + drift * 30, y: -200 + drift * 20)
                .blur(radius: 60)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            NestPalette.bondSpark.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: 100 - drift * 20, y: 250 - drift * 15)
                .blur(radius: 50)

            EmberParticlesView()
                .opacity(0.5)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                drift = 1
            }
        }
    }
}

// MARK: - Card Style Modifier

struct NestCardStyle: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(NestPalette.blanketCharcoal)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(NestPalette.moonThread, lineWidth: 0.5)
            )
    }
}

extension View {
    func nestCard(padding: CGFloat = 16) -> some View {
        modifier(NestCardStyle(padding: padding))
    }
}

// MARK: - Gold Button Style

struct HearthButtonStyle: ButtonStyle {
    var isCompact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isCompact ? .subheadline.bold() : .headline.bold())
            .foregroundColor(NestPalette.emberNight)
            .padding(.horizontal, isCompact ? 20 : 32)
            .padding(.vertical, isCompact ? 10 : 14)
            .background(
                LinearGradient(
                    colors: [NestPalette.hearthGold, NestPalette.candleAmber],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(isCompact ? 10 : 14)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Ghost / Outline Button Style

struct MoonlitButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundColor(NestPalette.duskWhisper)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(NestPalette.blanketCharcoal)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(NestPalette.moonThread, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
