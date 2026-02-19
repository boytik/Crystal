// HearthViewModel.swift
// Our Days: Easy Now
// ViewModel for the Hearth (Today) tab — separated from View per architecture rules

import SwiftUI
import Combine

// MARK: - Hearth ViewModel

@MainActor
final class HearthViewModel: ObservableObject {

    // MARK: Published State

    @Published var quickDeeds: [DeedButtonState] = []
    @Published var recentMoments: [MomentRowState] = []
    @Published var selectedDay: HearthDay = .today
    @Published var gentleNudge: GentleNudge?
    @Published var sparkSnapshot: SparkSnapshot = SparkSnapshot()
    @Published var viewPhase: HearthPhase = .loading

    // Sheet triggers
    @Published var showWhoDid: Bool = false
    @Published var activeDeed: HearthDeed?

    // MARK: Dependencies

    private let vault: HearthVault
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    init(vault: HearthVault = .shared) {
        self.vault = vault
        observeVaultChanges()
    }

    // MARK: - Observe Vault

    private func observeVaultChanges() {
        // React to moments / deeds / souls changes
        vault.$emberMoments
            .combineLatest(vault.$hearthDeeds, vault.$kinSouls)
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshAll()
            }
            .store(in: &cancellables)

        vault.$sparkLedger
            .sink { [weak self] ledger in
                self?.updateSparkSnapshot(ledger)
            }
            .store(in: &cancellables)
    }

    // MARK: - Load / Refresh

    func loadHearth() {
        viewPhase = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshAll()
            withAnimation(.easeOut(duration: 0.3)) {
                self?.viewPhase = .ready
            }
        }
    }

    func refreshAll() {
        buildQuickDeeds()
        buildRecentMoments()
        buildGentleNudge()
        updateSparkSnapshot(vault.sparkLedger)

        if quickDeeds.isEmpty && recentMoments.isEmpty {
            viewPhase = .empty
        } else if viewPhase != .ready {
            viewPhase = .ready
        }
    }

    // MARK: - Day Switching

    func switchDay(_ day: HearthDay) {
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedDay = day
        }
        refreshAll()
    }

    private var targetDate: Date {
        switch selectedDay {
        case .today:     return Date()
        case .yesterday: return Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        }
    }

    // MARK: - Build Quick Deeds

    private func buildQuickDeeds() {
        let moments = vault.momentsForDate(targetDate)

        quickDeeds = vault.activeDeeds.map { deed in
            let count = moments.filter { $0.deedId == deed.id }.count
            return DeedButtonState(
                deed: deed,
                todayCount: count,
                hasActivity: count > 0
            )
        }
    }

    // MARK: - Build Recent Moments

    private func buildRecentMoments() {
        let moments = vault.momentsForDate(targetDate)
        let souls = vault.kinSouls
        let deeds = vault.hearthDeeds

        recentMoments = moments.prefix(15).map { moment in
            let soul = souls.first(where: { $0.id == moment.kinSoulId })
            let deed = deeds.first(where: { $0.id == moment.deedId })
            return MomentRowState(
                moment: moment,
                kinName: soul?.nestName ?? "Unknown",
                kinEmoji: soul?.spiritEmoji ?? "❓",
                kinColorSeed: soul?.colorSeed ?? 0,
                deedName: deed?.deedName ?? "Unknown",
                deedIcon: deed?.deedIcon ?? "questionmark",
                timeString: moment.happenedAt.shortTimeString,
                hasGratitude: moment.hasGratitude,
                tinyNote: moment.tinyNote
            )
        }
    }

    // MARK: - Gentle Nudge

    private func buildGentleNudge() {
        let weekMoments = vault.momentsForWeek(containing: Date())
        guard weekMoments.count >= 5 else {
            gentleNudge = nil
            return
        }

        // Find the most done deed this week
        let grouped = Dictionary(grouping: weekMoments, by: { $0.deedId })
        if let topEntry = grouped.max(by: { $0.value.count < $1.value.count }),
           let deed = vault.hearthDeeds.first(where: { $0.id == topEntry.key }) {

            let pct = Int(Double(topEntry.value.count) / Double(weekMoments.count) * 100)

            if pct > 40 {
                gentleNudge = GentleNudge(
                    icon: "lightbulb.fill",
                    message: "\"\(deed.deedName)\" accounts for \(pct)% of this week — maybe split it into smaller steps?",
                    nudgeType: .suggestion
                )
            } else {
                // Check balance between members
                let memberGroups = Dictionary(grouping: weekMoments, by: { $0.kinSoulId })
                let counts = memberGroups.map { $0.value.count }
                if let maxCount = counts.max(), let minCount = counts.min(),
                   counts.count >= 2, maxCount > minCount * 3 {
                    gentleNudge = GentleNudge(
                        icon: "arrow.left.arrow.right",
                        message: "The load seems uneven this week — a quick chat might help balance things.",
                        nudgeType: .balance
                    )
                } else {
                    gentleNudge = nil
                }
            }
        }
    }

    // MARK: - Spark Snapshot

    private func updateSparkSnapshot(_ ledger: BondSparkLedger) {
        sparkSnapshot = SparkSnapshot(
            totalSparks: ledger.totalSparks,
            currentStreak: ledger.currentStreak,
            clanLevel: ledger.clanLevel,
            clanEmoji: ledger.clanLevel.icon,
            weeklyProgress: ledger.weeklySparkGoal > 0
                ? min(1.0, Double(ledger.weeklySparksCurrent) / Double(ledger.weeklySparkGoal))
                : 0,
            weeklyCurrent: ledger.weeklySparksCurrent,
            weeklyGoal: ledger.weeklySparkGoal,
            badgesCount: ledger.unlockedBadges.count
        )
    }

    // MARK: - Actions

    func tapDeed(_ deed: HearthDeed) {
        activeDeed = deed
        showWhoDid = true
    }

    func confirmQuickLog(deed: HearthDeed, soul: KinSoul, time: Date = Date(), note: String? = nil) {
        let moment = EmberMoment(
            deedId: deed.id,
            kinSoulId: soul.id,
            happenedAt: time,
            tinyNote: note
        )
        vault.logEmberMoment(moment)
        showWhoDid = false
        activeDeed = nil
    }

    func toggleGratitude(momentId: UUID, fromKinId: UUID) {
        vault.toggleGratitude(momentId: momentId, fromKinId: fromKinId)
    }

    func deleteMoment(_ momentId: UUID) {
        vault.deleteEmberMoment(id: momentId)
    }

    func dismissNudge() {
        withAnimation(.easeOut(duration: 0.3)) {
            gentleNudge = nil
        }
    }
}

// MARK: - State Models

struct DeedButtonState: Identifiable {
    let deed: HearthDeed
    let todayCount: Int
    let hasActivity: Bool

    var id: UUID { deed.id }
}

struct MomentRowState: Identifiable {
    let moment: EmberMoment
    let kinName: String
    let kinEmoji: String
    let kinColorSeed: Int
    let deedName: String
    let deedIcon: String
    let timeString: String
    let hasGratitude: Bool
    let tinyNote: String?

    var id: UUID { moment.id }
}

struct GentleNudge: Equatable {
    let icon: String
    let message: String
    let nudgeType: NudgeType

    enum NudgeType: Equatable {
        case suggestion
        case balance
        case encouragement
    }
}

struct SparkSnapshot: Equatable {
    var totalSparks: Int = 0
    var currentStreak: Int = 0
    var clanLevel: ClanLevel = .seedling
    var clanEmoji: String = "🌱"
    var weeklyProgress: Double = 0
    var weeklyCurrent: Int = 0
    var weeklyGoal: Int = 30
    var badgesCount: Int = 0
}

enum HearthDay: String, CaseIterable, Identifiable {
    case today = "Today"
    case yesterday = "Yesterday"

    var id: String { rawValue }
}

enum HearthPhase {
    case loading
    case ready
    case empty
}
