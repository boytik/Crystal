// ClanNookView.swift
// Our Days: Easy Now
// View for Clan Nook (Family/Settings) tab — separated from ViewModel per architecture rules

import SwiftUI

// MARK: - Clan Nook View (Family Tab)

struct ClanNookView: View {
    @StateObject private var vm = ClanNookViewModel()
    @EnvironmentObject var coordinator: NestCoordinator

    var body: some View {
        NavigationStack {
            ZStack {
                EmberNightBackground()

                mainContent
                    .navigationTitle("Clan")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarColorScheme(.dark, for: .navigationBar)

                EmberToastOverlay()
            }
        }
        .nestAlerts()
        .sheet(isPresented: $vm.showShareSheet) {
            ShareSheetWrapper(text: vm.exportText)
        }
        .onAppear { vm.loadClan() }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch vm.viewPhase {
        case .loading:
            clanSkeleton
        case .ready:
            readyContent
        }
    }

    // MARK: - Ready Content

    private var readyContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // User avatar card
                avatarCard
                    .padding(.horizontal, 16)

                // Family members
                membersSection
                    .padding(.horizontal, 16)

                // Quick actions / deeds
                deedsSection
                    .padding(.horizontal, 16)

                // Stats dashboard
                statsSection
                    .padding(.horizontal, 16)

                // Preferences
                preferencesSection
                    .padding(.horizontal, 16)

                // Danger zone
                dangerZone
                    .padding(.horizontal, 16)

                Spacer(minLength: 32)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Avatar Card

    private var avatarCard: some View {
        HStack(spacing: 16) {
            // Big avatar
            Button {
                coordinator.openAvatarPicker()
            } label: {
                Text(vm.userAvatarEmoji)
                    .font(.system(size: 48))
                    .frame(width: 72, height: 72)
                    .background(NestPalette.hearthGold.opacity(0.12))
                    .cornerRadius(36)
                    .overlay(
                        Circle()
                            .stroke(NestPalette.hearthGold.opacity(0.3), lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption)
                            .foregroundColor(NestPalette.hearthGold)
                            .offset(x: 26, y: 26)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Our Days")
                    .font(.title3.weight(.bold))
                    .foregroundColor(NestPalette.snowfall)

                HStack(spacing: 6) {
                    Text(vm.clanStats.clanEmoji)
                        .font(.caption)
                    Text(vm.clanStats.clanLevel)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(NestPalette.hearthGold)
                }

                Text("\(vm.activeKin.count) members · \(vm.clanStats.totalMoments) moments")
                    .font(.caption2)
                    .foregroundColor(NestPalette.shadowMurmur)
            }

            Spacer()
        }
        .nestCard()
    }

    // MARK: - Members Section

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("Family Members")

                Spacer()

                if vm.activeKin.count < 6 {
                    Button {
                        coordinator.openAddKinSoul()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(NestPalette.hearthGold)
                    }
                }
            }

            VStack(spacing: 2) {
                ForEach(vm.activeKin) { soul in
                    memberRow(soul)

                    if soul.id != vm.activeKin.last?.id {
                        Divider()
                            .background(NestPalette.moonThread.opacity(0.5))
                            .padding(.leading, 60)
                    }
                }
            }
            .background(NestPalette.blanketCharcoal)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(NestPalette.moonThread, lineWidth: 0.5)
            )

            // Archived members expandable
            if !vm.archivedKin.isEmpty {
                DisclosureGroup {
                    VStack(spacing: 2) {
                        ForEach(vm.archivedKin) { soul in
                            archivedMemberRow(soul)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "archivebox.fill")
                            .font(.caption)
                        Text("Archived (\(vm.archivedKin.count))")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(NestPalette.shadowMurmur)
                }
            }
        }
    }

    private func memberRow(_ soul: KinSoul) -> some View {
        Button {
            coordinator.openEditKinSoul(soul)
        } label: {
            HStack(spacing: 12) {
                Text(soul.spiritEmoji)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(NestPalette.kinColor(at: soul.colorSeed).opacity(0.15))
                    .cornerRadius(20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(soul.nestName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(NestPalette.snowfall)

                    Text(soul.kinRole.rawValue)
                        .font(.caption2)
                        .foregroundColor(NestPalette.shadowMurmur)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(NestPalette.moonThread)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .contextMenu {
            Button(role: .destructive) {
                coordinator.confirmArchiveMember(soul)
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
        }
    }

    private func archivedMemberRow(_ soul: KinSoul) -> some View {
        HStack(spacing: 12) {
            Text(soul.spiritEmoji)
                .font(.caption)
                .frame(width: 30, height: 30)
                .background(NestPalette.moonThread.opacity(0.3))
                .cornerRadius(15)
                .opacity(0.6)

            Text(soul.nestName)
                .font(.caption.weight(.medium))
                .foregroundColor(NestPalette.shadowMurmur)

            Spacer()

            Button {
                vm.restoreKinSoul(soul)
            } label: {
                Text("Restore")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(NestPalette.harmonyMoss)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(NestPalette.harmonyMoss.opacity(0.12))
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    // MARK: - Deeds Section

    private var deedsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("Quick Actions")

                Spacer()

                Button {
                    coordinator.openAddCustomDeed()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(NestPalette.hearthGold)
                }
            }

            // Active deeds grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ], spacing: 10) {
                ForEach(vm.activeDeeds) { deed in
                    deedChip(deed)
                }
            }

            // Archived deeds
            if !vm.archivedDeeds.isEmpty {
                DisclosureGroup {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                    ], spacing: 8) {
                        ForEach(vm.archivedDeeds) { deed in
                            archivedDeedChip(deed)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "archivebox.fill")
                            .font(.caption)
                        Text("Archived (\(vm.archivedDeeds.count))")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(NestPalette.shadowMurmur)
                }
            }
        }
    }

    private func deedChip(_ deed: HearthDeed) -> some View {
        Button {
            coordinator.openEditDeed(deed)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: deed.deedIcon)
                    .font(.caption.bold())
                    .foregroundColor(NestPalette.hearthGold)

                Text(deed.deedName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(NestPalette.snowfall)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(NestPalette.blanketCharcoal)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(NestPalette.moonThread, lineWidth: 0.5)
            )
        }
        .contextMenu {
            Button(role: .destructive) {
                vm.archiveDeed(deed)
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
        }
    }

    private func archivedDeedChip(_ deed: HearthDeed) -> some View {
        HStack(spacing: 4) {
            Image(systemName: deed.deedIcon)
                .font(.system(size: 9))
            Text(deed.deedName)
                .font(.system(size: 9, weight: .medium))
                .lineLimit(1)
        }
        .foregroundColor(NestPalette.shadowMurmur)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(NestPalette.moonThread.opacity(0.3))
        .cornerRadius(8)
        .onTapGesture {
            vm.restoreDeed(deed)
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("Clan Statistics")

                Spacer()

                Button {
                    coordinator.openStatsDashboard()
                } label: {
                    Text("Details")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(NestPalette.hearthGold)
                }
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ], spacing: 10) {
                statCell(icon: "flame.fill", value: "\(vm.clanStats.totalMoments)", label: "Moments", color: NestPalette.hearthGold)
                statCell(icon: "heart.fill", value: "\(vm.clanStats.totalGratitudes)", label: "Thanks", color: NestPalette.bondSpark)
                statCell(icon: "calendar", value: "\(vm.clanStats.daysActive)", label: "Days Active", color: NestPalette.harmonyMoss)
                statCell(icon: "bolt.fill", value: "\(vm.clanStats.currentStreak)d", label: "Current Streak", color: NestPalette.streakEmber)
                statCell(icon: "trophy.fill", value: "\(vm.clanStats.badgesUnlocked)/\(vm.clanStats.badgesTotal)", label: "Badges", color: NestPalette.bondSpark)
                statCell(icon: "crown.fill", value: "\(vm.clanStats.longestStreak)d", label: "Best Streak", color: NestPalette.candleAmber)
            }

            // Top member + top deed row
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Text(vm.clanStats.topMemberEmoji)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("MVP")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(NestPalette.shadowMurmur)
                        Text(vm.clanStats.topMemberName)
                            .font(.caption.weight(.bold))
                            .foregroundColor(NestPalette.snowfall)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(NestPalette.blanketCharcoal)
                .cornerRadius(10)

                HStack(spacing: 8) {
                    Image(systemName: vm.clanStats.topDeedIcon)
                        .font(.title3)
                        .foregroundColor(NestPalette.hearthGold)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Top Action")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(NestPalette.shadowMurmur)
                        Text(vm.clanStats.topDeedName)
                            .font(.caption.weight(.bold))
                            .foregroundColor(NestPalette.snowfall)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(NestPalette.blanketCharcoal)
                .cornerRadius(10)
            }
        }
    }

    private func statCell(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundColor(color)

            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(NestPalette.snowfall)

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

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Preferences")

            VStack(spacing: 0) {
                prefToggle(
                    icon: "heart.circle.fill",
                    title: "Gentle Summaries",
                    subtitle: "No comparisons or rankings",
                    isOn: Binding(get: { vm.softModeOn }, set: { _ in vm.toggleSoftMode() }),
                    tint: NestPalette.harmonyMoss
                )

                prefDivider

                prefToggle(
                    icon: "speaker.wave.2.fill",
                    title: "Spark Sounds",
                    subtitle: "Play sound when logging",
                    isOn: Binding(get: { vm.sparkSoundOn }, set: { _ in vm.toggleSparkSound() }),
                    tint: NestPalette.hearthGold
                )

                prefDivider

                prefToggle(
                    icon: "calendar",
                    title: "Week Starts Monday",
                    subtitle: "Affects weekly summaries",
                    isOn: Binding(get: { vm.weekStartsMonday }, set: { _ in vm.toggleWeekStart() }),
                    tint: NestPalette.bondSpark
                )

                prefDivider

                // Badge gallery button
                prefButton(
                    icon: "trophy.fill",
                    title: "Badge Gallery",
                    subtitle: "\(vm.clanStats.badgesUnlocked) unlocked",
                    tint: NestPalette.candleAmber
                ) {
                    coordinator.openBadgeGallery()
                }

                prefDivider

                // Export button
                prefButton(
                    icon: "square.and.arrow.up",
                    title: "Share Weekly Summary",
                    subtitle: "Export as text",
                    tint: NestPalette.hearthGold
                ) {
                    vm.prepareExport()
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

    private func prefToggle(icon: String, title: String, subtitle: String, isOn: Binding<Bool>, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(NestPalette.snowfall)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(NestPalette.shadowMurmur)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(tint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func prefButton(icon: String, title: String, subtitle: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(tint)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(NestPalette.snowfall)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(NestPalette.shadowMurmur)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(NestPalette.moonThread)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
    }

    private var prefDivider: some View {
        Divider()
            .background(NestPalette.moonThread.opacity(0.5))
            .padding(.leading, 54)
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Data")

            Button {
                coordinator.confirmResetAllData()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "trash.fill")
                        .font(.body)
                        .foregroundColor(NestPalette.nudgeRose)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset All Data")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(NestPalette.nudgeRose)
                        Text("Erase everything and start fresh")
                            .font(.caption2)
                            .foregroundColor(NestPalette.shadowMurmur)
                    }

                    Spacer()
                }
                .padding(14)
                .background(NestPalette.nudgeRose.opacity(0.06))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(NestPalette.nudgeRose.opacity(0.15), lineWidth: 0.5)
                )
                .contentShape(Rectangle())
            }

            // App version
            HStack {
                Spacer()
                Text("Our Days: Easy Now · v1.0")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(NestPalette.shadowMurmur)
                Spacer()
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.headline.weight(.bold))
            .foregroundColor(NestPalette.snowfall)
    }

    // MARK: - Skeleton

    private var clanSkeleton: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(NestPalette.blanketCharcoal)
                .frame(height: 90)
                .padding(.horizontal, 16)
                .shimmerEffect()

            RoundedRectangle(cornerRadius: 14)
                .fill(NestPalette.blanketCharcoal)
                .frame(height: 120)
                .padding(.horizontal, 16)
                .shimmerEffect()

            RoundedRectangle(cornerRadius: 14)
                .fill(NestPalette.blanketCharcoal)
                .frame(height: 80)
                .padding(.horizontal, 16)
                .shimmerEffect()

            RoundedRectangle(cornerRadius: 14)
                .fill(NestPalette.blanketCharcoal)
                .frame(height: 160)
                .padding(.horizontal, 16)
                .shimmerEffect()

            Spacer()
        }
        .padding(.top, 12)
    }
}

// MARK: - Share Sheet Wrapper

struct ShareSheetWrapper: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
