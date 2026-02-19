// ClanNookViewModel.swift
// Our Days: Easy Now
// ViewModel for the Clan Nook (Family/Settings) tab — separated from View per architecture rules

import SwiftUI
import Combine

// MARK: - Clan Nook ViewModel

@MainActor
final class ClanNookViewModel: ObservableObject {

    // MARK: Published State — Members

    @Published var activeKin: [KinSoul] = []
    @Published var archivedKin: [KinSoul] = []

    // MARK: Published State — Deeds

    @Published var activeDeeds: [HearthDeed] = []
    @Published var archivedDeeds: [HearthDeed] = []

    // MARK: Published State — Preferences

    @Published var softModeOn: Bool = true
    @Published var sparkSoundOn: Bool = true
    @Published var weekStartsMonday: Bool = true
    @Published var userAvatarEmoji: String = "🏠"

    // MARK: Published State — Stats Overview

    @Published var clanStats: ClanStatsSnapshot = ClanStatsSnapshot()

    // MARK: Published State — UI

    @Published var viewPhase: ClanPhase = .loading
    @Published var showShareSheet: Bool = false
    @Published var exportText: String = ""

    // MARK: Dependencies

    private let vault: HearthVault
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    init(vault: HearthVault = .shared) {
        self.vault = vault
        observeChanges()
    }

    // MARK: - Observe

    private func observeChanges() {
        vault.$kinSouls
            .combineLatest(vault.$hearthDeeds, vault.$emberMoments)
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildAll()
            }
            .store(in: &cancellables)

        vault.$nestPreferences
            .sink { [weak self] prefs in
                self?.syncPreferences(prefs)
            }
            .store(in: &cancellables)

        vault.$sparkLedger
            .sink { [weak self] ledger in
                self?.updateStatsFromLedger(ledger)
            }
            .store(in: &cancellables)
    }

    // MARK: - Load

    func loadClan() {
        viewPhase = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.rebuildAll()
            self?.syncPreferences(self?.vault.nestPreferences ?? NestPreferences())
            withAnimation(.easeOut(duration: 0.3)) {
                self?.viewPhase = .ready
            }
        }
    }

    // MARK: - Rebuild

    private func rebuildAll() {
        let souls = vault.kinSouls
        activeKin = souls.filter { !$0.isArchived }
        archivedKin = souls.filter { $0.isArchived }

        let deeds = vault.hearthDeeds
        activeDeeds = deeds.filter { !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }
        archivedDeeds = deeds.filter { $0.isArchived }

        buildStats()
    }

    private func syncPreferences(_ prefs: NestPreferences) {
        softModeOn = prefs.softModeEnabled
        sparkSoundOn = prefs.sparkSoundEnabled
        weekStartsMonday = prefs.weekStartsOnMonday
        userAvatarEmoji = prefs.userAvatarEmoji
    }

    // MARK: - Member Actions

    func addKinSoul(name: String, role: KinRole, emoji: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let colorSeed = vault.kinSouls.count
        let soul = KinSoul(
            nestName: name,
            kinRole: role,
            spiritEmoji: emoji,
            colorSeed: colorSeed
        )
        vault.addKinSoul(soul)
    }

    func updateKinSoul(_ soul: KinSoul) {
        vault.updateKinSoul(soul)
    }

    func archiveKinSoul(_ soul: KinSoul) {
        vault.archiveKinSoul(id: soul.id)
    }

    func restoreKinSoul(_ soul: KinSoul) {
        var restored = soul
        restored.isArchived = false
        vault.updateKinSoul(restored)
    }

    // MARK: - Deed Actions

    func addCustomDeed(name: String, icon: String, domain: DeedDomain) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let deed = HearthDeed(
            deedName: name,
            deedIcon: icon,
            deedDomain: domain,
            sortOrder: vault.hearthDeeds.count,
            isDefault: false
        )
        vault.addHearthDeed(deed)
    }

    func updateDeed(_ deed: HearthDeed) {
        vault.updateHearthDeed(deed)
    }

    func archiveDeed(_ deed: HearthDeed) {
        vault.archiveHearthDeed(id: deed.id)
    }

    func restoreDeed(_ deed: HearthDeed) {
        var restored = deed
        restored.isArchived = false
        vault.updateHearthDeed(restored)
    }

    // MARK: - Preferences Actions

    func toggleSoftMode() {
        softModeOn.toggle()
        vault.nestPreferences.softModeEnabled = softModeOn
        vault.savePreferences()
    }

    func toggleSparkSound() {
        sparkSoundOn.toggle()
        vault.nestPreferences.sparkSoundEnabled = sparkSoundOn
        vault.savePreferences()
    }

    func toggleWeekStart() {
        weekStartsMonday.toggle()
        vault.nestPreferences.weekStartsOnMonday = weekStartsMonday
        vault.savePreferences()
    }

    func setUserAvatar(_ emoji: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            userAvatarEmoji = emoji
        }
        vault.nestPreferences.userAvatarEmoji = emoji
        vault.savePreferences()
    }

    // MARK: - Stats

    private func buildStats() {
        let allMoments = vault.emberMoments
        let gratitudes = allMoments.filter { $0.hasGratitude }.count
        let topDeed = vault.mostActiveDeed()

        // Days active
        let uniqueDays = Set(allMoments.map { $0.dayKey })
        let daysActive = uniqueDays.count

        // Most active member
        let grouped = Dictionary(grouping: allMoments, by: { $0.kinSoulId })
        let topMemberId = grouped.max(by: { $0.value.count < $1.value.count })?.key
        let topMember = topMemberId.flatMap { id in vault.kinSouls.first(where: { $0.id == id }) }

        clanStats = ClanStatsSnapshot(
            totalMoments: allMoments.count,
            totalGratitudes: gratitudes,
            daysActive: daysActive,
            membersCount: activeKin.count,
            topDeedName: topDeed?.deedName ?? "—",
            topDeedIcon: topDeed?.deedIcon ?? "star.fill",
            topMemberName: topMember?.nestName ?? "—",
            topMemberEmoji: topMember?.spiritEmoji ?? "❓",
            currentStreak: vault.sparkLedger.currentStreak,
            longestStreak: vault.sparkLedger.longestStreak,
            clanLevel: vault.sparkLedger.clanLevel.rawValue,
            clanEmoji: vault.sparkLedger.clanLevel.icon,
            badgesUnlocked: vault.sparkLedger.unlockedBadges.count,
            badgesTotal: NestBadgeCatalog.allBadges.count
        )
    }

    private func updateStatsFromLedger(_ ledger: BondSparkLedger) {
        clanStats.currentStreak = ledger.currentStreak
        clanStats.longestStreak = ledger.longestStreak
        clanStats.clanLevel = ledger.clanLevel.rawValue
        clanStats.clanEmoji = ledger.clanLevel.icon
        clanStats.badgesUnlocked = ledger.unlockedBadges.count
    }

    // MARK: - Export

    func prepareExport() {
        exportText = vault.exportWeeklySummary(for: Date())
        showShareSheet = true
    }

    // MARK: - Reset

    func resetAllData() {
        vault.resetAllData()
    }
}

// MARK: - State Models

struct ClanStatsSnapshot {
    var totalMoments: Int = 0
    var totalGratitudes: Int = 0
    var daysActive: Int = 0
    var membersCount: Int = 0
    var topDeedName: String = "—"
    var topDeedIcon: String = "star.fill"
    var topMemberName: String = "—"
    var topMemberEmoji: String = "❓"
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var clanLevel: String = "Seedling Nest"
    var clanEmoji: String = "🌱"
    var badgesUnlocked: Int = 0
    var badgesTotal: Int = 10
}

enum ClanPhase {
    case loading
    case ready
}

// MARK: - Avatar Emoji Catalog

enum SpiritEmojiCatalog {
    static let familyEmojis: [String] = [
        "🏠", "🏡", "🌳", "🔥", "✨",
        "🌙", "☀️", "🌈", "🦋", "🐦",
        "🌸", "🌻", "🍀", "🎯", "🎨",
        "🧡", "💙", "💚", "💜", "💛",
        "🤎", "🩷", "🖤", "🩵", "❤️",
        "😊", "😎", "🥰", "🤗", "😇",
        "👑", "🌟", "💎", "🎭", "🎪",
        "🦁", "🐻", "🐱", "🐶", "🦊",
        "🐼", "🦉", "🐸", "🦄", "🐝",
    ]

    static let memberEmojis: [String] = [
        "🧡", "💙", "💚", "💜", "💛",
        "🤎", "🩷", "🖤", "🩵", "❤️",
        "🌟", "⭐", "✨", "💫", "🔥",
        "🌸", "🌺", "🌻", "🌷", "🌹",
        "👩", "👨", "👵", "👴", "🧑",
        "😊", "😎", "🥰", "🤗", "😇",
    ]

    static let deedIcons: [String] = [
        "drop.fill", "figure.walk", "moon.zzz.fill", "book.fill",
        "puzzlepiece.fill", "frying.pan.fill", "cup.and.saucer.fill",
        "sparkles", "washer.fill", "cart.fill", "heart.fill",
        "star.fill", "leaf.fill", "paintbrush.fill", "music.note",
        "car.fill", "cross.case.fill", "graduationcap.fill",
        "scissors", "hammer.fill", "wrench.fill", "bag.fill",
        "phone.fill", "envelope.fill", "gift.fill", "hands.sparkles.fill",
    ]
}
