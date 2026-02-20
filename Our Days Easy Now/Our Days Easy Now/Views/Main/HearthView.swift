// HearthView.swift
// Our Days: Easy Now
// View for the Hearth (Today) tab — separated from ViewModel per architecture rules

import SwiftUI

// MARK: - Hearth View (Today Tab)

struct HearthView: View {
    @StateObject private var vm = HearthViewModel()
    @EnvironmentObject var coordinator: NestCoordinator
    @State private var isQuickActionsExpanded = false

    var body: some View {
        NavigationStack {
            ZStack {
                EmberNightBackground()

                mainContent
                    .navigationTitle("Hearth")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarColorScheme(.dark, for: .navigationBar)

                EmberToastOverlay()
            }
        }
        .sheet(isPresented: $vm.showWhoDid) {
            if let deed = vm.activeDeed {
                WhoDidSheet(deed: deed)
                    .environmentObject(coordinator)
            }
        }
        .nestAlerts()
        .onAppear { vm.loadHearth() }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch vm.viewPhase {
        case .loading:
            hearthSkeleton
        case .empty:
            emptyHearth
        case .ready:
            readyContent
        }
    }

    // MARK: - Ready Content

    private var readyContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Day switcher + spark bar
                dayAndSparkHeader
                    .padding(.horizontal, 16)

                // Quick action deeds grid
                deedGrid
                    .padding(.horizontal, 16)

                // Gentle nudge card
                if let nudge = vm.gentleNudge {
                    nudgeCard(nudge)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Recent moments
                recentSection
                    .padding(.horizontal, 16)

                // Gamification strip
                sparkStripCard
                    .padding(.horizontal, 16)

                Spacer(minLength: 32)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Day Switcher + Spark Bar

    private var dayAndSparkHeader: some View {
        VStack(spacing: 14) {
            // Day toggle
            HStack(spacing: 0) {
                ForEach(HearthDay.allCases) { day in
                    Button {
                        vm.switchDay(day)
                    } label: {
                        Text(NSLocalizedString(day.rawValue, comment: ""))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(
                                vm.selectedDay == day ? NestPalette.emberNight : NestPalette.duskWhisper
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                vm.selectedDay == day
                                    ? NestPalette.hearthGold
                                    : Color.clear
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

            // Weekly spark progress
            weeklySparkBar
        }
    }

    private var weeklySparkBar: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.caption.bold())
                    .foregroundColor(NestPalette.hearthGold)

                Text("Weekly Sparks")
                    .font(.caption.weight(.medium))
                    .foregroundColor(NestPalette.duskWhisper)

                Spacer()

                Text("\(vm.sparkSnapshot.weeklyCurrent)/\(vm.sparkSnapshot.weeklyGoal)")
                    .font(.caption.bold())
                    .foregroundColor(NestPalette.hearthGold)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(NestPalette.moonThread)
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [NestPalette.hearthGold, NestPalette.candleAmber],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * vm.sparkSnapshot.weeklyProgress, height: 6)
                        .animation(.easeInOut(duration: 0.5), value: vm.sparkSnapshot.weeklyProgress)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(NestPalette.blanketCharcoal.opacity(0.6))
        .cornerRadius(10)
    }

    // MARK: - Deed Grid

    private var deedGrid: some View {
        let deedsToShow = isQuickActionsExpanded
            ? Array(vm.quickDeeds)
            : Array(vm.quickDeeds.prefix(4))
        let canExpand = vm.quickDeeds.count > 4

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Actions")
                    .font(.headline.weight(.bold))
                    .foregroundColor(NestPalette.snowfall)

                Spacer()

                HStack(spacing: 4) {
                    if canExpand {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isQuickActionsExpanded.toggle()
                            }
                        } label: {
                            Image(systemName: isQuickActionsExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                .font(.title3)
                                .foregroundColor(NestPalette.hearthGold)
                                .contentShape(Rectangle())
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        coordinator.openAddCustomDeed()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(NestPalette.hearthGold)
                            .contentShape(Rectangle())
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ], spacing: 12) {
                ForEach(deedsToShow) { item in
                    deedButton(item)
                }
            }
        }
    }

    private func deedButton(_ item: DeedButtonState) -> some View {
        Button {
            vm.tapDeed(item.deed)
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.deed.deedIcon)
                        .font(.title2)
                        .foregroundColor(
                            item.hasActivity ? NestPalette.hearthGold : NestPalette.duskWhisper
                        )
                        .frame(maxWidth: .infinity)

                    // Count badge
                    if item.todayCount > 0 {
                        Text("\(item.todayCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(NestPalette.emberNight)
                            .frame(width: 20, height: 20)
                            .background(NestPalette.hearthGold)
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Text(item.deed.deedName)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(NestPalette.snowfall)
                    .lineLimit(1)

                // Domain dot
                Text(NSLocalizedString(item.deed.deedDomain.rawValue, comment: ""))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(NestPalette.shadowMurmur)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                item.hasActivity
                    ? NestPalette.hearthGold.opacity(0.08)
                    : NestPalette.blanketCharcoal
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        item.hasActivity
                            ? NestPalette.hearthGold.opacity(0.3)
                            : NestPalette.moonThread,
                        lineWidth: item.hasActivity ? 1 : 0.5
                    )
            )
        }
        .buttonStyle(DeedTapStyle())
        .accessibilityLabel("\(item.deed.deedName), \(item.todayCount) logged today")
        .accessibilityHint("Double tap to log who did this")
    }

    // MARK: - Nudge Card

    private func nudgeCard(_ nudge: GentleNudge) -> some View {
        HStack(spacing: 12) {
            Image(systemName: nudge.icon)
                .font(.title3)
                .foregroundColor(NestPalette.candleAmber)
                .frame(width: 36)

            Text(nudge.message)
                .font(.caption.weight(.medium))
                .foregroundColor(NestPalette.duskWhisper)
                .lineSpacing(3)

            Spacer(minLength: 4)

            Button {
                vm.dismissNudge()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.bold())
                    .foregroundColor(NestPalette.shadowMurmur)
                    .padding(6)
            }
        }
        .padding(14)
        .background(
            NestPalette.candleAmber.opacity(0.08)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(NestPalette.candleAmber.opacity(0.2), lineWidth: 0.5)
        )
    }

    // MARK: - Recent Moments Section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Moments")
                    .font(.headline.weight(.bold))
                    .foregroundColor(NestPalette.snowfall)

                Spacer()

                if !vm.recentMoments.isEmpty {
                    Button {
                        coordinator.switchTo(.taleScroll)
                    } label: {
                        Text("See All")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(NestPalette.hearthGold)
                    }
                }
            }

            if vm.recentMoments.isEmpty {
                emptyMomentsPlaceholder
            } else {
                VStack(spacing: 2) {
                    ForEach(vm.recentMoments.prefix(8)) { row in
                        momentRow(row)
                    }
                }
                .background(NestPalette.blanketCharcoal)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(NestPalette.moonThread, lineWidth: 0.5)
                )
            }
        }
    }

    private func momentRow(_ row: MomentRowState) -> some View {
        HStack(spacing: 12) {
            // Kin emoji
            Text(row.kinEmoji)
                .font(.title3)
                .frame(width: 38, height: 38)
                .background(
                    NestPalette.kinColor(at: row.kinColorSeed).opacity(0.15)
                )
                .cornerRadius(19)

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(row.kinName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(NestPalette.snowfall)

                    Image(systemName: row.deedIcon)
                        .font(.caption)
                        .foregroundColor(NestPalette.hearthGold)

                    Text(row.deedName)
                        .font(.subheadline)
                        .foregroundColor(NestPalette.duskWhisper)
                }

                HStack(spacing: 6) {
                    Text(row.timeString)
                        .font(.caption2)
                        .foregroundColor(NestPalette.shadowMurmur)

                    if let note = row.tinyNote, !note.isEmpty {
                        Text("• \(note)")
                            .font(.caption2)
                            .foregroundColor(NestPalette.shadowMurmur)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Gratitude indicator
            if row.hasGratitude {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(NestPalette.bondSpark)
            }

            // Time badge
            Text(row.timeString)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(NestPalette.shadowMurmur)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                let firstSoul = HearthVault.shared.activeKinSouls.first
                if let soulId = firstSoul?.id {
                    vm.toggleGratitude(momentId: row.moment.id, fromKinId: soulId)
                }
            } label: {
                Label(
                    row.hasGratitude ? "Remove Thanks" : "Say Thanks 💛",
                    systemImage: row.hasGratitude ? "heart.slash" : "heart.fill"
                )
            }

            Button(role: .destructive) {
                vm.deleteMoment(row.moment.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var emptyMomentsPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(NestPalette.moonThread)

            Text("No moments yet")
                .font(.subheadline.weight(.medium))
                .foregroundColor(NestPalette.duskWhisper)

            Text("Tap an action above to log the first one")
                .font(.caption)
                .foregroundColor(NestPalette.shadowMurmur)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(NestPalette.blanketCharcoal)
        .cornerRadius(14)
    }

    // MARK: - Spark / Gamification Strip

    private var sparkStripCard: some View {
        HStack(spacing: 16) {
            // Clan level
            sparkBubble(
                emoji: vm.sparkSnapshot.clanEmoji,
                label: NSLocalizedString(vm.sparkSnapshot.clanLevel.rawValue, comment: ""),
                valueColor: NestPalette.hearthGold
            )

            dividerLine

            // Streak
            sparkBubble(
                emoji: "🔥",
                label: "\(vm.sparkSnapshot.currentStreak) day streak",
                valueColor: NestPalette.streakEmber
            )

            dividerLine

            // Badges
            Button {
                coordinator.openBadgeGallery()
            } label: {
                sparkBubble(
                    emoji: "🏅",
                    label: "\(vm.sparkSnapshot.badgesCount) badges",
                    valueColor: NestPalette.bondSpark
                )
            }
        }
        .padding(14)
        .background(NestPalette.blanketCharcoal)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(NestPalette.moonThread, lineWidth: 0.5)
        )
    }

    private func sparkBubble(emoji: String, label: String, valueColor: Color) -> some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.title2)

            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(valueColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(NestPalette.moonThread)
            .frame(width: 1, height: 36)
    }

    // MARK: - Empty State

    private var emptyHearth: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "flame")
                .font(.system(size: 56))
                .foregroundColor(NestPalette.moonThread)

            Text("Your hearth is quiet")
                .font(.title3.weight(.semibold))
                .foregroundColor(NestPalette.duskWhisper)

            Text("Add family members and actions\nin the Clan tab to get started")
                .font(.subheadline)
                .foregroundColor(NestPalette.shadowMurmur)
                .multilineTextAlignment(.center)

            Button {
                coordinator.switchTo(.clanNook)
            } label: {
                HStack {
                    Image(systemName: "house.fill")
                    Text("Open Clan")
                }
            }
            .buttonStyle(HearthButtonStyle())

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Skeleton Loading

    private var hearthSkeleton: some View {
        VStack(spacing: 20) {
            // Fake day switcher
            RoundedRectangle(cornerRadius: 12)
                .fill(NestPalette.blanketCharcoal)
                .frame(height: 44)
                .padding(.horizontal, 16)

            // Fake deed grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ], spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 14)
                        .fill(NestPalette.blanketCharcoal)
                        .frame(height: 80)
                        .shimmerEffect()
                }
            }
            .padding(.horizontal, 16)

            // Fake moments
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 0)
                        .fill(NestPalette.blanketCharcoal)
                        .frame(height: 56)
                        .shimmerEffect()
                }
            }
            .cornerRadius(14)
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.top, 16)
    }
}

// MARK: - Deed Tap Button Style

struct DeedTapStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            NestPalette.moonThread.opacity(0.3),
                            Color.clear,
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: geo.size.width * phase)
                    .onAppear {
                        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                            phase = 1.5
                        }
                    }
                }
            )
            .clipped()
    }
}

extension View {
    func shimmerEffect() -> some View {
        modifier(ShimmerModifier())
    }
}
