// TaleScrollView.swift
// Our Days: Easy Now
// View for Tale Scroll (Feed) tab — separated from ViewModel per architecture rules

import SwiftUI

// MARK: - Tale Scroll View (Feed Tab)

struct TaleScrollView: View {
    @StateObject private var vm = TaleScrollViewModel()
    @EnvironmentObject var coordinator: NestCoordinator

    var body: some View {
        NavigationStack {
            ZStack {
                EmberNightBackground()

                mainContent
                    .navigationTitle("Tales")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .toolbar { toolbarItems }

                EmberToastOverlay()
            }
        }
        .nestAlerts()
        .onAppear { vm.loadTales() }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                vm.toggleFilterBar()
            } label: {
                Image(systemName: vm.filter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .foregroundColor(vm.filter.isActive ? NestPalette.hearthGold : NestPalette.duskWhisper)
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch vm.viewPhase {
        case .loading:
            taleSkeleton
        case .empty:
            emptyTales
        case .filtered:
            noFilterResults
        case .ready:
            readyContent
        }
    }

    // MARK: - Ready Content

    private var readyContent: some View {
        VStack(spacing: 0) {
            // Period picker
            periodPicker
                .padding(.horizontal, 16)
                .padding(.top, 8)

            // Filter bar (collapsible)
            if vm.showFilterBar {
                filterBar
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Search
            searchBar
                .padding(.horizontal, 16)
                .padding(.top, 10)

            // Stats strip
            statsStrip
                .padding(.horizontal, 16)
                .padding(.top, 10)

            // Grouped list
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                    ForEach(vm.groupedTales) { group in
                        Section {
                            VStack(spacing: 10) {
                                ForEach(group.moments) { row in
                                    taleRow(row)
                                }
                            }
                            .padding(.horizontal, 16)
                        } header: {
                            daySectionHeader(group)
                                .padding(.horizontal, 16)
                        }
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top, 12)
            }
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(TalePeriod.allCases) { period in
                Button {
                    vm.setPeriod(period)
                } label: {
                    Text(NSLocalizedString(period.rawValue, comment: ""))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(
                            vm.filter.period == period
                                ? NestPalette.emberNight
                                : NestPalette.duskWhisper
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            vm.filter.period == period
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
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Kin pills
            if !vm.availableKin.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Family")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(NestPalette.shadowMurmur)
                        .padding(.leading, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(vm.availableKin) { soul in
                                kinPill(soul)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }

            // Deed pills
            if !vm.availableDeeds.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Actions")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(NestPalette.shadowMurmur)
                        .padding(.leading, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(vm.availableDeeds) { deed in
                                deedPill(deed)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }

            // Domain pills
            VStack(alignment: .leading, spacing: 6) {
                Text("Category")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(NestPalette.shadowMurmur)
                    .padding(.leading, 16)

                HStack(spacing: 8) {
                    ForEach(DeedDomain.allCases) { domain in
                        domainPill(domain)
                    }

                    Spacer()

                    // Clear all button
                    if vm.filter.isActive {
                        Button {
                            vm.clearAllFilters()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                Text("Clear")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundColor(NestPalette.nudgeRose)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(NestPalette.nudgeRose.opacity(0.12))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(NestPalette.cradleDark.opacity(0.8))
    }

    private func kinPill(_ soul: KinSoul) -> some View {
        let isSelected = vm.filter.selectedKinIds.contains(soul.id)
        return Button {
            vm.toggleKinFilter(soul.id)
        } label: {
            HStack(spacing: 6) {
                Text(soul.spiritEmoji)
                    .font(.caption)
                Text(soul.nestName)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(isSelected ? NestPalette.emberNight : NestPalette.duskWhisper)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? NestPalette.hearthGold : NestPalette.blanketCharcoal)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? NestPalette.hearthGold : NestPalette.moonThread,
                        lineWidth: 0.5
                    )
            )
        }
    }

    private func deedPill(_ deed: HearthDeed) -> some View {
        let isSelected = vm.filter.selectedDeedIds.contains(deed.id)
        return Button {
            vm.toggleDeedFilter(deed.id)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: deed.deedIcon)
                    .font(.system(size: 10))
                Text(deed.deedName)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(isSelected ? NestPalette.emberNight : NestPalette.duskWhisper)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isSelected ? NestPalette.hearthGold : NestPalette.blanketCharcoal)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? NestPalette.hearthGold : NestPalette.moonThread,
                        lineWidth: 0.5
                    )
            )
        }
    }

    private func domainPill(_ domain: DeedDomain) -> some View {
        let isSelected = vm.filter.selectedDomain == domain
        return Button {
            vm.setDomainFilter(domain)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: domain.tinyIcon)
                    .font(.system(size: 10))
                Text(NSLocalizedString(domain.rawValue, comment: ""))
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(isSelected ? NestPalette.emberNight : NestPalette.duskWhisper)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isSelected ? NestPalette.harmonyMoss : NestPalette.blanketCharcoal)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? NestPalette.harmonyMoss : NestPalette.moonThread,
                        lineWidth: 0.5
                    )
            )
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundColor(NestPalette.shadowMurmur)

            TextField("Search moments...", text: $vm.searchText)
                .font(.subheadline)
                .foregroundColor(NestPalette.snowfall)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()

            if !vm.searchText.isEmpty {
                Button {
                    vm.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(NestPalette.shadowMurmur)
                }
            }
        }
        .padding(10)
        .background(NestPalette.blanketCharcoal)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(NestPalette.moonThread, lineWidth: 0.5)
        )
    }

    // MARK: - Stats Strip

    private var statsStrip: some View {
        HStack(spacing: 0) {
            statChip(
                icon: "flame.fill",
                value: "\(vm.totalCount)",
                label: "moments",
                color: NestPalette.hearthGold,
                animated: true
            )

            Rectangle()
                .fill(NestPalette.moonThread)
                .frame(width: 1, height: 40)

            statChip(
                icon: "heart.fill",
                value: "\(vm.gratitudeCount)",
                label: "thanks",
                color: NestPalette.bondSpark,
                animated: true
            )

            Rectangle()
                .fill(NestPalette.moonThread)
                .frame(width: 1, height: 40)

            statChip(
                icon: "calendar",
                value: vm.filter.period.rawValue,
                label: "period",
                color: NestPalette.harmonyMoss,
                animated: true
            )
        }
        .padding(.vertical, 12)
        .background(NestPalette.blanketCharcoal.opacity(0.5))
        .cornerRadius(10)
    }

    private func statChip(icon: String, value: String, label: String, color: Color, animated: Bool = false) -> some View {
        HStack(spacing: 10) {
            if animated {
                TaleAnimatedStatIcon(systemName: icon, color: color)
            } else {
                Image(systemName: icon)
                    .font(.title3.bold())
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.body.bold())
                    .foregroundColor(NestPalette.snowfall)
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(NestPalette.duskWhisper)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Day Section Header

    private func daySectionHeader(_ group: TaleDayGroup) -> some View {
        HStack {
            Text(group.dayLabel)
                .font(.subheadline.weight(.bold))
                .foregroundColor(NestPalette.snowfall)

            Spacer()

            Text("\(group.momentCount) moments")
                .font(.caption2.weight(.medium))
                .foregroundColor(NestPalette.shadowMurmur)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(NestPalette.blanketCharcoal)
                .cornerRadius(6)
        }
        .padding(.vertical, 6)
        .background(NestPalette.emberNight.opacity(0.95))
    }

    // MARK: - Moment Row

    private func taleRow(_ row: TaleMomentRow) -> some View {
        HStack(spacing: 12) {
            // Avatar
            Text(row.kinEmoji)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(
                    NestPalette.kinColor(at: row.kinColorSeed).opacity(0.3)
                )
                .cornerRadius(20)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(row.kinName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(NestPalette.emberNight)

                    Image(systemName: row.deedIcon)
                        .font(.caption2)
                        .foregroundColor(NestPalette.emberNight)

                    Text(row.deedName)
                        .font(.subheadline)
                        .foregroundColor(NestPalette.emberNight.opacity(0.85))
                }

                HStack(spacing: 6) {
                    // Domain tag
                    HStack(spacing: 3) {
                        Image(systemName: row.deedDomain.tinyIcon)
                            .font(.system(size: 9, weight: .medium))
                        Text(NSLocalizedString(row.deedDomain.rawValue, comment: ""))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(NestPalette.emberNight.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(NestPalette.emberNight.opacity(0.12))
                    .cornerRadius(6)

                    if let note = row.tinyNote, !note.isEmpty {
                        Text(note)
                            .font(.caption2)
                            .foregroundColor(NestPalette.emberNight.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Right side
            VStack(alignment: .trailing, spacing: 4) {
                Text(row.timeString)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(NestPalette.emberNight.opacity(0.65))

                if row.hasGratitude {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(NestPalette.bondSpark)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(NestPalette.hearthGold)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(NestPalette.candleAmber.opacity(0.5), lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .contextMenu {
            // Gratitude toggle
            Button {
                vm.toggleGratitude(momentId: row.moment.id)
            } label: {
                Label(
                    row.hasGratitude ? "Remove Thanks" : "Say Thanks 💛",
                    systemImage: row.hasGratitude ? "heart.slash" : "heart.fill"
                )
            }

            // Copy moment text
            Button {
                let text = "\(row.kinName) — \(row.deedName) at \(row.timeString)"
                UIPasteboard.general.string = text
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

            Divider()

            // Delete
            Button(role: .destructive) {
                vm.deleteMoment(row.moment.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                vm.deleteMoment(row.moment.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                vm.toggleGratitude(momentId: row.moment.id)
            } label: {
                Label("Thanks", systemImage: "heart.fill")
            }
            .tint(NestPalette.bondSpark)
        }
    }

    // MARK: - Empty State

    private var emptyTales: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "scroll")
                .font(.system(size: 52))
                .foregroundColor(NestPalette.moonThread)

            Text("No tales yet")
                .font(.title3.weight(.semibold))
                .foregroundColor(NestPalette.duskWhisper)

            Text("Log moments on the Hearth tab\nand they'll appear here as your family story")
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

    // MARK: - No Filter Results

    private var noFilterResults: some View {
        VStack(spacing: 0) {
            // Same structure as readyContent to prevent layout shift
            periodPicker
                .padding(.horizontal, 16)
                .padding(.top, 8)

            if vm.showFilterBar {
                filterBar
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
            }

            searchBar
                .padding(.horizontal, 16)
                .padding(.top, 10)

            statsStrip
                .padding(.horizontal, 16)
                .padding(.top, 10)

            // Empty state (replaces ScrollView content)
            VStack(spacing: 16) {
                Spacer(minLength: 24)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 44))
                    .foregroundColor(NestPalette.moonThread)

                Text("No moments match these filters")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(NestPalette.duskWhisper)

                Button {
                    vm.clearAllFilters()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Clear Filters")
                    }
                }
                .buttonStyle(MoonlitButtonStyle())

                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Skeleton

    private var taleSkeleton: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(NestPalette.blanketCharcoal)
                .frame(height: 42)
                .padding(.horizontal, 16)
                .shimmerEffect()

            RoundedRectangle(cornerRadius: 10)
                .fill(NestPalette.blanketCharcoal)
                .frame(height: 38)
                .padding(.horizontal, 16)
                .shimmerEffect()

            ForEach(0..<5, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 14)
                    .fill(NestPalette.blanketCharcoal)
                    .frame(height: 62)
                    .padding(.horizontal, 16)
                    .shimmerEffect()
            }

            Spacer()
        }
        .padding(.top, 12)
    }
}

// MARK: - Animated Stat Icon (Tales)

private struct TaleAnimatedStatIcon: View {
    let systemName: String
    let color: Color
    @State private var scale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Image(systemName: systemName)
            .font(.title3.bold())
            .foregroundColor(color)
            .scaleEffect(reduceMotion ? 1.0 : scale)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    scale = 1.15
                }
            }
    }
}
