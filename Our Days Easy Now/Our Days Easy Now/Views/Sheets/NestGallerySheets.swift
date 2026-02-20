// NestGallerySheets.swift
// Our Days: Easy Now
// Secondary sheets — Badge Gallery, Avatar Picker, Stats Dashboard, Export Summary

import SwiftUI

// MARK: - Badge Gallery Sheet

struct BadgeGallerySheet: View {
    @ObservedObject private var vault = HearthVault.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedBadge: NestBadge?
    @State private var appearAnimated: Bool = false

    private var allBadges: [NestBadge] {
        NestBadgeCatalog.allBadges.map { catalog in
            if let unlocked = vault.sparkLedger.unlockedBadges.first(where: { $0.id == catalog.id }) {
                return unlocked
            }
            return catalog
        }
    }

    private var unlockedCount: Int {
        vault.sparkLedger.unlockedBadges.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NestPalette.cradleDark.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Trophy header
                        trophyHeader

                        // Progress ring
                        progressRing

                        // Badge grid
                        badgeGrid

                        // Selected badge detail
                        if let badge = selectedBadge {
                            badgeDetail(badge)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Badge Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(NestPalette.hearthGold)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                    appearAnimated = true
                }
            }
        }
    }

    private var trophyHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(NestPalette.hearthGold.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .blur(radius: 15)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [NestPalette.hearthGold, NestPalette.candleAmber],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(appearAnimated ? 1.0 : 0.5)
                    .opacity(appearAnimated ? 1 : 0)
            }

            Text("\(unlockedCount) of \(NestBadgeCatalog.allBadges.count) Unlocked")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(NestPalette.duskWhisper)
        }
    }

    private var progressRing: some View {
        let progress = Double(unlockedCount) / Double(max(1, NestBadgeCatalog.allBadges.count))

        return ZStack {
            Circle()
                .stroke(NestPalette.moonThread, lineWidth: 6)
                .frame(width: 100, height: 100)

            Circle()
                .trim(from: 0, to: appearAnimated ? progress : 0)
                .stroke(
                    LinearGradient(
                        colors: [NestPalette.hearthGold, NestPalette.bondSpark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.0), value: appearAnimated)

            Text("\(Int(progress * 100))%")
                .font(.title3.bold())
                .foregroundColor(NestPalette.hearthGold)
        }
    }

    private var badgeGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ], spacing: 12) {
            ForEach(Array(allBadges.enumerated()), id: \.element.id) { index, badge in
                badgeCell(badge, index: index)
            }
        }
    }

    private func badgeCell(_ badge: NestBadge, index: Int) -> some View {
        let isUnlocked = badge.isUnlocked
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedBadge = (selectedBadge?.id == badge.id) ? nil : badge
            }
        } label: {
            VStack(spacing: 6) {
                Text(badge.badgeIcon)
                    .font(.system(size: 32))
                    .grayscale(isUnlocked ? 0 : 1)
                    .opacity(isUnlocked ? 1 : 0.35)

                Text(badge.badgeTitle)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isUnlocked ? NestPalette.snowfall : NestPalette.shadowMurmur)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // Lock / check indicator
                Image(systemName: isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(isUnlocked ? NestPalette.harmonyMoss : NestPalette.shadowMurmur)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                isUnlocked
                    ? NestPalette.hearthGold.opacity(0.06)
                    : NestPalette.blanketCharcoal
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isUnlocked ? NestPalette.hearthGold.opacity(0.3) : NestPalette.moonThread,
                        lineWidth: isUnlocked ? 1.5 : 0.5
                    )
            )
            .scaleEffect(appearAnimated ? 1.0 : 0.8)
            .opacity(appearAnimated ? 1 : 0)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.05),
                value: appearAnimated
            )
        }
    }

    private func badgeDetail(_ badge: NestBadge) -> some View {
        VStack(spacing: 10) {
            Text(badge.badgeIcon)
                .font(.system(size: 44))

            Text(badge.badgeTitle)
                .font(.headline.weight(.bold))
                .foregroundColor(NestPalette.snowfall)

            Text(badge.badgeDesc)
                .font(.subheadline)
                .foregroundColor(NestPalette.duskWhisper)
                .multilineTextAlignment(.center)

            if let date = badge.unlockedAt {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(NestPalette.harmonyMoss)
                    Text("Unlocked \(date.friendlyDayString)")
                        .foregroundColor(NestPalette.harmonyMoss)
                }
                .font(.caption.weight(.medium))
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(NestPalette.shadowMurmur)
                    Text("Keep going to unlock!")
                        .foregroundColor(NestPalette.shadowMurmur)
                }
                .font(.caption.weight(.medium))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(NestPalette.blanketCharcoal)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    badge.isUnlocked
                        ? NestPalette.hearthGold.opacity(0.3)
                        : NestPalette.moonThread,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Avatar Picker Sheet

struct AvatarPickerSheet: View {
    @ObservedObject private var vault = HearthVault.shared
    @Environment(\.dismiss) private var dismiss

    @State private var chosenEmoji: String

    init() {
        _chosenEmoji = State(initialValue: HearthVault.shared.nestPreferences.userAvatarEmoji)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NestPalette.cradleDark.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Preview
                        VStack(spacing: 10) {
                            Text(chosenEmoji)
                                .font(.system(size: 72))
                                .frame(width: 100, height: 100)
                                .background(NestPalette.hearthGold.opacity(0.12))
                                .cornerRadius(50)
                                .overlay(
                                    Circle()
                                        .stroke(NestPalette.hearthGold.opacity(0.4), lineWidth: 2)
                                )

                            Text("Your Clan Avatar")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(NestPalette.duskWhisper)
                        }

                        // Emoji sections
                        emojiSection(title: "Hearts & Feelings", emojis: [
                            "🧡", "💙", "💚", "💜", "💛", "🤎", "🩷", "🖤", "🩵", "❤️", "🤍", "💗",
                        ])

                        emojiSection(title: "Nature & Home", emojis: [
                            "🏠", "🏡", "🌳", "🔥", "✨", "🌙", "☀️", "🌈", "🌸", "🌻", "🍀", "🌊",
                        ])

                        emojiSection(title: "Animals", emojis: [
                            "🦋", "🐦", "🦁", "🐻", "🐱", "🐶", "🦊", "🐼", "🦉", "🐸", "🦄", "🐝",
                        ])

                        emojiSection(title: "Fun & Sparkle", emojis: [
                            "👑", "🌟", "💎", "🎯", "🎨", "🎭", "🎪", "🚀", "⚡", "🎶", "🎮", "🧩",
                        ])

                        // Save
                        Button {
                            save()
                        } label: {
                            Text("Set Avatar")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HearthButtonStyle())

                        Spacer(minLength: 32)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(NestPalette.duskWhisper)
                }
            }
        }
    }

    private func emojiSection(title: String, emojis: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(NestPalette.shadowMurmur)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                ForEach(emojis, id: \.self) { emoji in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                            chosenEmoji = emoji
                        }
                    } label: {
                        Text(emoji)
                            .font(.title2)
                            .frame(width: 46, height: 46)
                            .background(
                                chosenEmoji == emoji
                                    ? NestPalette.hearthGold.opacity(0.2)
                                    : NestPalette.blanketCharcoal
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        chosenEmoji == emoji
                                            ? NestPalette.hearthGold
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .scaleEffect(chosenEmoji == emoji ? 1.1 : 1.0)
                    }
                }
            }
        }
    }

    private func save() {
        vault.nestPreferences.userAvatarEmoji = chosenEmoji
        vault.savePreferences()
        dismiss()
    }
}

// MARK: - Stats Dashboard Sheet

struct StatsDashboardSheet: View {
    @ObservedObject private var vault = HearthVault.shared
    @Environment(\.dismiss) private var dismiss

    @State private var animateIn: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                NestPalette.cradleDark.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Lifetime header
                        lifetimeHeader

                        // Stats grid
                        statsGrid

                        // Per-member breakdown
                        memberBreakdown

                        // Per-deed breakdown
                        deedBreakdown

                        // Fun facts
                        funFactsCard

                        Spacer(minLength: 32)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Clan Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(NestPalette.hearthGold)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                    animateIn = true
                }
            }
        }
    }

    private var lifetimeHeader: some View {
        VStack(spacing: 8) {
            Text(vault.sparkLedger.clanLevel.icon)
                .font(.system(size: 48))
                .scaleEffect(animateIn ? 1.0 : 0.5)
                .opacity(animateIn ? 1 : 0)

            Text("All-Time Overview")
                .font(.title3.weight(.bold))
                .foregroundColor(NestPalette.snowfall)

            Text(NSLocalizedString(vault.sparkLedger.clanLevel.rawValue, comment: ""))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(NestPalette.hearthGold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var statsGrid: some View {
        let moments = vault.emberMoments
        let gratitudes = moments.filter { $0.hasGratitude }.count
        let uniqueDays = Set(moments.map { $0.dayKey }).count
        let avgPerDay = uniqueDays > 0 ? Double(moments.count) / Double(uniqueDays) : 0

        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
        ], spacing: 10) {
            dashStat(icon: "flame.fill", value: "\(moments.count)", label: "Total Moments", color: NestPalette.hearthGold)
            dashStat(icon: "heart.fill", value: "\(gratitudes)", label: "Thanks Given", color: NestPalette.bondSpark)
            dashStat(icon: "calendar", value: "\(uniqueDays)", label: "Days Active", color: NestPalette.harmonyMoss)
            dashStat(icon: "chart.line.uptrend.xyaxis", value: String(format: "%.1f", avgPerDay), label: "Avg / Day", color: NestPalette.candleAmber)
            dashStat(icon: "bolt.fill", value: "\(vault.sparkLedger.totalSparks)", label: "Total Sparks", color: NestPalette.hearthGold)
            dashStat(icon: "crown.fill", value: "\(vault.sparkLedger.longestStreak)d", label: "Best Streak", color: NestPalette.streakEmber)
        }
    }

    private func dashStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundColor(color)

            Text(value)
                .font(.title3.bold())
                .foregroundColor(NestPalette.snowfall)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(NestPalette.shadowMurmur)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(NestPalette.blanketCharcoal)
        .cornerRadius(12)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 10)
    }

    private var memberBreakdown: some View {
        let grouped = Dictionary(grouping: vault.emberMoments, by: { $0.kinSoulId })

        return VStack(alignment: .leading, spacing: 12) {
            Text("By Member")
                .font(.headline.weight(.bold))
                .foregroundColor(NestPalette.snowfall)

            VStack(spacing: 8) {
                ForEach(vault.activeKinSouls) { soul in
                    let count = grouped[soul.id]?.count ?? 0
                    let total = max(1, vault.emberMoments.count)
                    let fraction = Double(count) / Double(total)

                    HStack(spacing: 10) {
                        Text(soul.spiritEmoji)
                            .font(.title3)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(soul.nestName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(NestPalette.snowfall)
                                Spacer()
                                Text("\(count) · \(Int(fraction * 100))%")
                                    .font(.caption2.bold())
                                    .foregroundColor(NestPalette.kinColor(at: soul.colorSeed))
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(NestPalette.moonThread.opacity(0.4))
                                        .frame(height: 5)

                                    Capsule()
                                        .fill(NestPalette.kinColor(at: soul.colorSeed))
                                        .frame(width: geo.size.width * (animateIn ? fraction : 0), height: 5)
                                        .animation(.easeOut(duration: 0.8), value: animateIn)
                                }
                            }
                            .frame(height: 5)
                        }
                    }
                }
            }
            .nestCard()
        }
    }

    private var deedBreakdown: some View {
        let grouped = Dictionary(grouping: vault.emberMoments, by: { $0.deedId })
        let sorted = vault.activeDeeds
            .map { deed in (deed: deed, count: grouped[deed.id]?.count ?? 0) }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }

        let maxCount = sorted.first?.count ?? 1

        return VStack(alignment: .leading, spacing: 12) {
            Text("By Action")
                .font(.headline.weight(.bold))
                .foregroundColor(NestPalette.snowfall)

            VStack(spacing: 8) {
                ForEach(sorted.prefix(8), id: \.deed.id) { item in
                    let fraction = Double(item.count) / Double(maxCount)

                    HStack(spacing: 10) {
                        Image(systemName: item.deed.deedIcon)
                            .font(.caption)
                            .foregroundColor(NestPalette.hearthGold)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.deed.deedName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(NestPalette.snowfall)
                                Spacer()
                                Text("\(item.count)")
                                    .font(.caption2.bold())
                                    .foregroundColor(NestPalette.hearthGold)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(NestPalette.moonThread.opacity(0.4))
                                        .frame(height: 5)

                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [NestPalette.hearthGold, NestPalette.candleAmber],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * (animateIn ? fraction : 0), height: 5)
                                        .animation(.easeOut(duration: 0.8), value: animateIn)
                                }
                            }
                            .frame(height: 5)
                        }
                    }
                }
            }
            .nestCard()
        }
    }

    private var funFactsCard: some View {
        let moments = vault.emberMoments
        guard !moments.isEmpty else { return AnyView(EmptyView()) }

        let hourCounts = Dictionary(grouping: moments) {
            Calendar.current.component(.hour, from: $0.happenedAt)
        }
        let peakHour = hourCounts.max(by: { $0.value.count < $1.value.count })?.key ?? 12
        let peakFormatted = formatHour(peakHour)

        let weekdayCounts = Dictionary(grouping: moments) {
            Calendar.current.component(.weekday, from: $0.happenedAt)
        }
        let peakWeekday = weekdayCounts.max(by: { $0.value.count < $1.value.count })?.key ?? 1
        let dayName = Calendar.current.weekdaySymbols[(peakWeekday - 1) % 7]

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text("Fun Facts")
                    .font(.headline.weight(.bold))
                    .foregroundColor(NestPalette.snowfall)

                VStack(spacing: 10) {
                    funFact(icon: "clock.fill", text: "Most active hour: \(peakFormatted)", color: NestPalette.hearthGold)
                    funFact(icon: "calendar", text: "Busiest day: \(dayName)", color: NestPalette.bondSpark)
                    funFact(icon: "person.2.fill", text: "\(vault.activeKinSouls.count) family members tracking together", color: NestPalette.harmonyMoss)
                }
                .nestCard()
            }
        )
    }

    private func funFact(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.caption.weight(.medium))
                .foregroundColor(NestPalette.duskWhisper)

            Spacer()
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var comps = DateComponents()
        comps.hour = hour
        if let date = Calendar.current.date(from: comps) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }
}

// MARK: - Export Summary Sheet

struct ExportSummarySheet: View {
    @ObservedObject private var vault = HearthVault.shared
    @Environment(\.dismiss) private var dismiss

    @State private var exportText: String = ""
    @State private var copied: Bool = false
    @State private var showShare: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                NestPalette.cradleDark.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Preview header
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 36))
                                .foregroundColor(NestPalette.hearthGold)

                            Text("Weekly Summary")
                                .font(.title3.weight(.bold))
                                .foregroundColor(NestPalette.snowfall)

                            Text("Share your family's week")
                                .font(.caption)
                                .foregroundColor(NestPalette.shadowMurmur)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)

                        // Preview text
                        Text(exportText)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(NestPalette.duskWhisper)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(NestPalette.blanketCharcoal)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(NestPalette.moonThread, lineWidth: 0.5)
                            )

                        // Action buttons
                        HStack(spacing: 12) {
                            Button {
                                copyToClipboard()
                            } label: {
                                HStack {
                                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    Text(copied ? "Copied!" : "Copy")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(MoonlitButtonStyle())

                            Button {
                                showShare = true
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(HearthButtonStyle(isCompact: true))
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(NestPalette.duskWhisper)
                }
            }
            .sheet(isPresented: $showShare) {
                ShareSheetWrapper(text: exportText)
            }
            .onAppear {
                exportText = vault.exportWeeklySummary(for: Date())
            }
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = exportText
        withAnimation(.easeInOut(duration: 0.2)) {
            copied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }
}
