// BondGlanceView.swift
// Our Days: Easy Now
// View for Bond Glance (Summary) tab — separated from ViewModel per architecture rules

import SwiftUI

// MARK: - Bond Glance View (Summary Tab)

struct BondGlanceView: View {
    @StateObject private var vm = BondGlanceViewModel()
    @EnvironmentObject var coordinator: NestCoordinator

    var body: some View {
        NavigationStack {
            ZStack {
                EmberNightBackground()

                mainContent
                    .navigationTitle("Bonds")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarColorScheme(.dark, for: .navigationBar)

                EmberToastOverlay()
            }
        }
        .nestAlerts()
        .onAppear { vm.loadGlance() }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch vm.viewPhase {
        case .loading:
            glanceSkeleton
        case .empty:
            emptyGlance
        case .ready:
            readyContent
        }
    }

    // MARK: - Ready Content

    private var readyContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                // Period picker
                periodPicker
                    .padding(.horizontal, 16)

                // Stats row
                statsRow
                    .padding(.horizontal, 16)

                // Team balance + insight
                balanceCard
                    .padding(.horizontal, 16)

                // Donut chart — member contributions
                if !vm.kinSlices.isEmpty {
                    donutSection
                        .padding(.horizontal, 16)
                }

                // Deed bar chart
                if !vm.deedBarItems.isEmpty {
                    deedBarSection
                        .padding(.horizontal, 16)
                }

                // Daily heatmap
                if !vm.dailyHeatmap.isEmpty {
                    heatmapSection
                        .padding(.horizontal, 16)
                }

                // Spark / Gamification progress
                sparkProgressCard
                    .padding(.horizontal, 16)

                Spacer(minLength: 32)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(GlancePeriod.allCases) { p in
                Button {
                    vm.switchPeriod(p)
                } label: {
                    Text(p.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(
                            vm.period == p ? NestPalette.emberNight : NestPalette.duskWhisper
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            vm.period == p ? NestPalette.hearthGold : Color.clear
                        )
                }
            }
        }
        .background(NestPalette.blanketCharcoal)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(NestPalette.moonThread, lineWidth: 0.5)
        )
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            miniStat(icon: "flame.fill", value: "\(vm.totalMoments)", label: "Moments", color: NestPalette.hearthGold)
            miniStat(icon: "heart.fill", value: "\(vm.totalGratitudes)", label: "Thanks", color: NestPalette.bondSpark)
            miniStat(icon: "star.fill", value: vm.topDeedName.isEmpty ? "—" : vm.topDeedName, label: "Top Action", color: NestPalette.harmonyMoss)
        }
    }

    private func miniStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundColor(color)

            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(NestPalette.snowfall)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(NestPalette.shadowMurmur)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(NestPalette.blanketCharcoal)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(NestPalette.moonThread, lineWidth: 0.5)
        )
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: vm.teamBalance.icon)
                    .font(.title3)
                    .foregroundColor(vm.teamBalance.tintColor)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Team Balance")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(NestPalette.shadowMurmur)

                    Text(vm.teamBalance.rawValue)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(vm.teamBalance.tintColor)
                }

                Spacer()
            }

            Text(vm.gentleInsight)
                .font(.caption.weight(.medium))
                .foregroundColor(NestPalette.duskWhisper)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .nestCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(vm.teamBalance.tintColor.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Donut Chart Section

    private var donutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Contributions")
                .font(.headline.weight(.bold))
                .foregroundColor(NestPalette.snowfall)

            HStack(spacing: 20) {
                // Donut
                ZStack {
                    nestDonut
                        .frame(width: 130, height: 130)

                    VStack(spacing: 2) {
                        Text("\(vm.totalMoments)")
                            .font(.title2.bold())
                            .foregroundColor(NestPalette.snowfall)
                        Text("total")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(NestPalette.shadowMurmur)
                    }
                }

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(vm.kinSlices) { slice in
                        kinLegendRow(slice)
                    }
                }
            }
            .padding(4)
        }
        .nestCard()
    }

    private var nestDonut: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 4
            let lineWidth: CGFloat = 20

            var startAngle: Angle = .degrees(-90)

            for slice in vm.kinSlices {
                let sweepAngle: Angle = .degrees(slice.percentage * 360)
                let endAngle = startAngle + sweepAngle
                let color = NestPalette.kinColor(at: slice.colorSeed)

                let path = Path { p in
                    p.addArc(
                        center: center,
                        radius: radius - lineWidth / 2,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false
                    )
                }

                context.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

                startAngle = endAngle
            }
        }
    }

    private func kinLegendRow(_ slice: KinSliceData) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(NestPalette.kinColor(at: slice.colorSeed))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(slice.kinEmoji)
                        .font(.caption)
                    Text(slice.kinName)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(NestPalette.snowfall)
                }

                Text("\(slice.momentCount) · \(Int(slice.percentage * 100))%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(NestPalette.shadowMurmur)
            }
        }
    }

    // MARK: - Deed Bar Chart

    private var deedBarSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Actions Breakdown")
                .font(.headline.weight(.bold))
                .foregroundColor(NestPalette.snowfall)

            VStack(spacing: 10) {
                ForEach(vm.deedBarItems.prefix(6)) { item in
                    deedBarRow(item)
                }
            }
        }
        .nestCard()
    }

    private func deedBarRow(_ item: DeedBarData) -> some View {
        VStack(spacing: 5) {
            HStack {
                Image(systemName: item.deedIcon)
                    .font(.caption2)
                    .foregroundColor(NestPalette.hearthGold)
                    .frame(width: 16)

                Text(item.deedName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(NestPalette.snowfall)

                Spacer()

                Text("\(item.count)")
                    .font(.caption.bold())
                    .foregroundColor(NestPalette.hearthGold)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(NestPalette.moonThread.opacity(0.4))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [NestPalette.hearthGold, NestPalette.candleAmber],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * item.fraction, height: 6)
                        .animation(.easeOut(duration: 0.6), value: item.fraction)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Daily Heatmap

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Daily Activity")
                    .font(.headline.weight(.bold))
                    .foregroundColor(NestPalette.snowfall)

                Spacer()

                // Legend
                HStack(spacing: 4) {
                    Text("less")
                        .font(.system(size: 8))
                        .foregroundColor(NestPalette.shadowMurmur)

                    ForEach([HeatIntensity.none, .low, .medium, .high, .blazing], id: \.rawValue) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(level.glowColor)
                            .frame(width: 10, height: 10)
                    }

                    Text("more")
                        .font(.system(size: 8))
                        .foregroundColor(NestPalette.shadowMurmur)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(vm.dailyHeatmap) { cell in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(cell.intensity.glowColor)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Group {
                                        if cell.momentCount > 0 {
                                            Text("\(cell.momentCount)")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(
                                                    cell.intensity >= .medium
                                                        ? NestPalette.emberNight
                                                        : NestPalette.duskWhisper
                                                )
                                        }
                                    }
                                )

                            Text(cell.dayLabel)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(NestPalette.shadowMurmur)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .nestCard()
    }

    // MARK: - Spark Progress Card

    private var sparkProgressCard: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                Text("Clan Progress")
                    .font(.headline.weight(.bold))
                    .foregroundColor(NestPalette.snowfall)

                Spacer()

                Button {
                    coordinator.openBadgeGallery()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.caption2)
                        Text("Badges")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(NestPalette.hearthGold)
                }
            }

            // Level display
            HStack(spacing: 16) {
                // Current level
                VStack(spacing: 4) {
                    Text(vm.sparkProgress.clanEmoji)
                        .font(.system(size: 40))

                    Text(vm.sparkProgress.clanName)
                        .font(.caption.weight(.bold))
                        .foregroundColor(NestPalette.hearthGold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(width: 90)

                // Progress bar + stats
                VStack(alignment: .leading, spacing: 10) {
                    // Progress to next level
                    if let next = vm.sparkProgress.nextLevelName {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Next: \(next)")
                                    .font(.caption2.weight(.medium))
                                    .foregroundColor(NestPalette.duskWhisper)
                                Spacer()
                                Text("\(vm.sparkProgress.sparksNeeded) sparks to go")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(NestPalette.hearthGold)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(NestPalette.moonThread)
                                        .frame(height: 8)

                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [NestPalette.hearthGold, NestPalette.streakEmber],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * vm.sparkProgress.progressToNext, height: 8)
                                        .animation(.easeOut(duration: 0.8), value: vm.sparkProgress.progressToNext)
                                }
                            }
                            .frame(height: 8)
                        }
                    }

                    // Mini stats row
                    HStack(spacing: 14) {
                        sparkMini(icon: "bolt.fill", value: "\(vm.sparkProgress.totalSparks)", label: "Sparks", color: NestPalette.hearthGold)
                        sparkMini(icon: "flame.fill", value: "\(vm.sparkProgress.currentStreak)d", label: "Streak", color: NestPalette.streakEmber)
                        sparkMini(icon: "trophy.fill", value: "\(vm.sparkProgress.badgesUnlocked)/\(vm.sparkProgress.badgesTotal)", label: "Badges", color: NestPalette.bondSpark)
                    }
                }
            }
        }
        .nestCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [NestPalette.hearthGold.opacity(0.3), NestPalette.streakEmber.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func sparkMini(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(color)
                Text(value)
                    .font(.caption2.bold())
                    .foregroundColor(NestPalette.snowfall)
            }
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(NestPalette.shadowMurmur)
        }
    }

    // MARK: - Empty State

    private var emptyGlance: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 52))
                .foregroundColor(NestPalette.moonThread)

            Text("No bonds to show yet")
                .font(.title3.weight(.semibold))
                .foregroundColor(NestPalette.duskWhisper)

            Text("Log a few moments on the Hearth tab\nand your team's story will appear here")
                .font(.subheadline)
                .foregroundColor(NestPalette.shadowMurmur)
                .multilineTextAlignment(.center)

            Button {
                coordinator.switchTo(.hearth)
            } label: {
                HStack {
                    Image(systemName: "flame.fill")
                    Text("Go to Hearth")
                }
            }
            .buttonStyle(HearthButtonStyle())

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Skeleton

    private var glanceSkeleton: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(NestPalette.blanketCharcoal)
                .frame(height: 42)
                .padding(.horizontal, 16)
                .shimmerEffect()

            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(NestPalette.blanketCharcoal)
                        .frame(height: 72)
                        .shimmerEffect()
                }
            }
            .padding(.horizontal, 16)

            RoundedRectangle(cornerRadius: 16)
                .fill(NestPalette.blanketCharcoal)
                .frame(height: 180)
                .padding(.horizontal, 16)
                .shimmerEffect()

            RoundedRectangle(cornerRadius: 16)
                .fill(NestPalette.blanketCharcoal)
                .frame(height: 140)
                .padding(.horizontal, 16)
                .shimmerEffect()

            Spacer()
        }
        .padding(.top, 12)
    }
}
