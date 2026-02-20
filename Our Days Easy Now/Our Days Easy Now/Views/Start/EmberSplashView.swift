// EmberSplashView.swift
// Our Days: Easy Now
// Splash / loading screen — abstract texts, animations, ember particles

import SwiftUI

struct EmberSplashView: View {
    let onFinished: () -> Void
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: Animation States

    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var progressValue: CGFloat = 0
    @State private var progressOpacity: Double = 0
    @State private var whisperIndex: Int = 0
    @State private var whisperOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var ringOpacity: Double = 0
    @State private var sparkBurst: Bool = false

    // Abstract loading whispers
    private let hearthWhispers: [String] = [
        "Warming the hearth…",
        "Gathering embers…",
        "Weaving family bonds…",
        "Lighting the way…",
        "Almost home…"
    ]

    var body: some View {
        ZStack {
            // Animated background
            AnimatedEmberSky()

            VStack(spacing: 0) {
                Spacer()

                // Spinning ring behind logo
                ringElement
                    .overlay(logoElement)

                Spacer().frame(height: 32)

                // App title
                titleBlock

                Spacer().frame(height: 40)

                // Loading whisper text
                whisperText

                Spacer().frame(height: 20)

                // Progress bar
                progressBar

                Spacer()

                // Bottom tagline
                bottomTagline
            }
            .padding(.horizontal, 32)

            // Spark burst overlay (skip when Reduce Motion)
            if sparkBurst && !reduceMotion {
                sparkBurstOverlay
                    .transition(.opacity)
            }
        }
        .onAppear(perform: startSequence)
    }

    // MARK: - Components

    private var ringElement: some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    colors: [
                        NestPalette.hearthGold.opacity(0.6),
                        NestPalette.hearthGold.opacity(0.1),
                        NestPalette.bondSpark.opacity(0.3),
                        NestPalette.hearthGold.opacity(0.6)
                    ],
                    center: .center
                ),
                lineWidth: 2
            )
            .frame(width: 140, height: 140)
            .rotationEffect(.degrees(ringRotation))
            .opacity(ringOpacity)
    }

    private var logoElement: some View {
        ZStack {
            // Glow behind
            Circle()
                .fill(NestPalette.hearthGold.opacity(0.15))
                .frame(width: 100, height: 100)
                .blur(radius: 20)

            // Main icon
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [NestPalette.hearthGold, NestPalette.candleAmber],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Tiny house beneath flame
                Image(systemName: "house.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(NestPalette.duskWhisper.opacity(0.6))
            }
        }
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text("Our Days")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(NestPalette.snowfall)

            Text("Easy Now")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [NestPalette.hearthGold, NestPalette.candleAmber],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .offset(y: titleOffset)
        .opacity(titleOpacity)
    }

    private var whisperText: some View {
        Text(hearthWhispers[whisperIndex])
            .font(.subheadline.weight(.medium))
            .foregroundColor(NestPalette.duskWhisper)
            .opacity(whisperOpacity)
            .animation(.easeInOut(duration: 0.4), value: whisperIndex)
            .frame(height: 24)
    }

    private var progressBar: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(NestPalette.moonThread)
                        .frame(height: 4)

                    // Fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [NestPalette.hearthGold, NestPalette.candleAmber],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progressValue, height: 4)

                    // Glow dot at tip
                    if progressValue > 0.05 {
                        Circle()
                            .fill(NestPalette.hearthGold)
                            .frame(width: 8, height: 8)
                            .shadow(color: NestPalette.hearthGold.opacity(0.6), radius: 6)
                            .offset(x: geo.size.width * progressValue - 4)
                    }
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 40)
        .opacity(progressOpacity)
    }

    private var bottomTagline: some View {
        Text("every moment matters")
            .font(.caption.weight(.medium))
            .foregroundColor(NestPalette.shadowMurmur)
            .tracking(2)
            .textCase(.uppercase)
            .opacity(subtitleOpacity)
            .padding(.bottom, 40)
    }

    private var sparkBurstOverlay: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(NestPalette.hearthGold)
                    .frame(width: CGFloat.random(in: 3...6), height: CGFloat.random(in: 3...6))
                    .offset(sparkOffset(index: i))
                    .opacity(sparkBurst ? 0 : 1)
                    .animation(
                        .easeOut(duration: 0.8).delay(Double(i) * 0.03),
                        value: sparkBurst
                    )
            }
        }
    }

    private func sparkOffset(index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 12.0) * .pi / 180
        let radius: CGFloat = sparkBurst ? 120 : 0
        return CGSize(
            width: CGFloat(cos(angle)) * radius,
            height: CGFloat(sin(angle)) * radius
        )
    }

    // MARK: - Animation Sequence

    private func startSequence() {
        // Phase 1: Ring + Logo appear (0.0s)
        withAnimation(.easeOut(duration: 0.8)) {
            ringOpacity = 1
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1
        }

        // Ring spin continuous
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }

        // Phase 2: Title slides in (0.5s)
        withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
            titleOffset = 0
            titleOpacity = 1
        }

        // Phase 3: Progress + whispers (0.8s)
        withAnimation(.easeIn(duration: 0.4).delay(0.8)) {
            progressOpacity = 1
            whisperOpacity = 1
        }

        // Phase 4: Progress animation (1.0s - 3.5s)
        withAnimation(.easeInOut(duration: 2.5).delay(1.0)) {
            progressValue = 1.0
        }

        // Whisper cycling
        cycleWhispers(startDelay: 1.0)

        // Phase 5: Bottom tagline (1.5s)
        withAnimation(.easeIn(duration: 0.5).delay(1.5)) {
            subtitleOpacity = 1
        }

        // Phase 6: Spark burst + finish (3.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                sparkBurst = true
            }
        }

        // Phase 7: Complete (4.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            onFinished()
        }
    }

    private func cycleWhispers(startDelay: Double) {
        for i in 1..<hearthWhispers.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + Double(i) * 0.6) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    whisperOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    whisperIndex = i
                    withAnimation(.easeInOut(duration: 0.3)) {
                        whisperOpacity = 1
                    }
                }
            }
        }
    }
}
