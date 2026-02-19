// BondGlanceViewModel.swift
// Our Days: Easy Now
// ViewModel for the Bond Glance (Summary) tab — separated from View per architecture rules

import SwiftUI
import Combine

// MARK: - Bond Glance ViewModel

@MainActor
final class BondGlanceViewModel: ObservableObject {

    // MARK: Published State

    @Published var weave: BondWeave?
    @Published var period: GlancePeriod = .week
    @Published var kinSlices: [KinSliceData] = []
    @Published var deedBarItems: [DeedBarData] = []
    @Published var dailyHeatmap: [DayHeatCell] = []
    @Published var gentleInsight: String = ""
    @Published var topDeedName: String = ""
    @Published var totalMoments: Int = 0
    @Published var totalGratitudes: Int = 0
    @Published var teamBalance: TeamBalanceLevel = .unknown
    @Published var sparkProgress: SparkProgressData = SparkProgressData()
    @Published var viewPhase: GlancePhase = .loading

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
        vault.$emberMoments
            .combineLatest(vault.$kinSouls, vault.$hearthDeeds)
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildGlance()
            }
            .store(in: &cancellables)

        vault.$sparkLedger
            .sink { [weak self] ledger in
                self?.buildSparkProgress(ledger)
            }
            .store(in: &cancellables)
    }

    // MARK: - Load

    func loadGlance() {
        viewPhase = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.rebuildGlance()
            withAnimation(.easeOut(duration: 0.4)) {
                self?.viewPhase = .ready
            }
        }
    }

    // MARK: - Period Switch

    func switchPeriod(_ newPeriod: GlancePeriod) {
        withAnimation(.easeInOut(duration: 0.25)) {
            period = newPeriod
        }
        rebuildGlance()
    }

    // MARK: - Rebuild All

    private func rebuildGlance() {
        let moments = fetchMoments()
        let souls = vault.activeKinSouls
        let deeds = vault.activeDeeds

        guard !moments.isEmpty else {
            totalMoments = 0
            totalGratitudes = 0
            kinSlices = []
            deedBarItems = []
            dailyHeatmap = []
            gentleInsight = "A fresh start awaits — every moment counts."
            topDeedName = ""
            teamBalance = .unknown
            weave = nil
            if viewPhase != .loading { viewPhase = .empty }
            return
        }

        totalMoments = moments.count
        totalGratitudes = moments.filter { $0.hasGratitude }.count

        buildKinSlices(moments: moments, souls: souls)
        buildDeedBars(moments: moments, deeds: deeds)
        buildDailyHeatmap(moments: moments)
        buildInsight(moments: moments, souls: souls)
        buildSparkProgress(vault.sparkLedger)

        // Build weave for current week
        weave = vault.buildBondWeave(for: Date())

        if viewPhase != .loading {
            viewPhase = .ready
        }
    }

    private func fetchMoments() -> [EmberMoment] {
        switch period {
        case .week:  return vault.momentsForWeek(containing: Date())
        case .month: return vault.momentsForMonth(containing: Date())
        }
    }

    // MARK: - Kin Slices (Donut chart data)

    private func buildKinSlices(moments: [EmberMoment], souls: [KinSoul]) {
        let grouped = Dictionary(grouping: moments, by: { $0.kinSoulId })
        let total = moments.count

        kinSlices = souls.compactMap { soul in
            let count = grouped[soul.id]?.count ?? 0
            guard count > 0 else { return nil }
            let pct = Double(count) / Double(total)

            // Top deed for this member
            let memberMoments = grouped[soul.id] ?? []
            let deedGroups = Dictionary(grouping: memberMoments, by: { $0.deedId })
            let topDeedId = deedGroups.max(by: { $0.value.count < $1.value.count })?.key
            let topDeedStr = topDeedId.flatMap { id in vault.hearthDeeds.first(where: { $0.id == id })?.deedName } ?? ""

            return KinSliceData(
                kinSoulId: soul.id,
                kinName: soul.nestName,
                kinEmoji: soul.spiritEmoji,
                colorSeed: soul.colorSeed,
                momentCount: count,
                percentage: pct,
                topDeed: topDeedStr
            )
        }
        .sorted { $0.momentCount > $1.momentCount }
    }

    // MARK: - Deed Bars (Bar chart data)

    private func buildDeedBars(moments: [EmberMoment], deeds: [HearthDeed]) {
        let grouped = Dictionary(grouping: moments, by: { $0.deedId })
        let maxCount = grouped.values.map { $0.count }.max() ?? 1

        deedBarItems = deeds.compactMap { deed in
            let count = grouped[deed.id]?.count ?? 0
            guard count > 0 else { return nil }
            return DeedBarData(
                deedId: deed.id,
                deedName: deed.deedName,
                deedIcon: deed.deedIcon,
                count: count,
                fraction: Double(count) / Double(maxCount)
            )
        }
        .sorted { $0.count > $1.count }

        topDeedName = deedBarItems.first?.deedName ?? ""
    }

    // MARK: - Daily Heatmap

    private func buildDailyHeatmap(moments: [EmberMoment]) {
        let cal = Calendar.current
        let daysCount = period == .week ? 7 : 30
        let today = Date()

        dailyHeatmap = (0..<daysCount).map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            let dayKey = date.nestDayKey
            let count = moments.filter { $0.dayKey == dayKey }.count

            let df = DateFormatter()
            df.dateFormat = "EEE"
            let label = offset == 0 ? "Today" : (offset == 1 ? "Yday" : df.string(from: date))

            return DayHeatCell(
                date: date,
                dayLabel: label,
                momentCount: count,
                intensity: intensityLevel(count)
            )
        }
        .reversed()
    }

    private func intensityLevel(_ count: Int) -> HeatIntensity {
        switch count {
        case 0:     return .none
        case 1...2: return .low
        case 3...5: return .medium
        case 6...9: return .high
        default:    return .blazing
        }
    }

    // MARK: - Insight & Balance

    private func buildInsight(moments: [EmberMoment], souls: [KinSoul]) {
        let grouped = Dictionary(grouping: moments, by: { $0.kinSoulId })
        let counts = souls.compactMap { grouped[$0.id]?.count }.filter { $0 > 0 }

        guard counts.count >= 2 else {
            teamBalance = .solo
            gentleInsight = counts.isEmpty
                ? "A fresh start awaits — every moment counts."
                : "Only one member has logged this period — teamwork makes it easier!"
            return
        }

        let maxC = counts.max() ?? 1
        let minC = counts.min() ?? 0
        let ratio = maxC > 0 ? Double(minC) / Double(maxC) : 1.0

        if ratio >= 0.7 {
            teamBalance = .balanced
            gentleInsight = "Great teamwork this \(period.rawValue.lowercased())! The load is well shared."
        } else if ratio >= 0.4 {
            teamBalance = .slight
            gentleInsight = "Mostly balanced — a small shift could even things out."
        } else if ratio >= 0.2 {
            teamBalance = .tilted
            gentleInsight = "One member carried more this \(period.rawValue.lowercased()) — a gentle conversation might help."
        } else {
            teamBalance = .heavy
            gentleInsight = "The load leaned heavily — consider discussing how to share."
        }
    }

    // MARK: - Spark Progress

    private func buildSparkProgress(_ ledger: BondSparkLedger) {
        let level = ledger.clanLevel
        let nextLevel = level.nextLevel

        let currentSparks = ledger.totalSparks
        let currentThreshold = level.sparksRequired
        let nextThreshold = nextLevel?.sparksRequired ?? currentThreshold

        let progressInLevel: Double
        if nextThreshold > currentThreshold {
            progressInLevel = Double(currentSparks - currentThreshold) / Double(nextThreshold - currentThreshold)
        } else {
            progressInLevel = 1.0
        }

        sparkProgress = SparkProgressData(
            clanLevel: level,
            clanEmoji: level.icon,
            clanName: level.rawValue,
            nextLevelName: nextLevel?.rawValue,
            totalSparks: currentSparks,
            progressToNext: min(1.0, max(0, progressInLevel)),
            sparksNeeded: max(0, nextThreshold - currentSparks),
            currentStreak: ledger.currentStreak,
            longestStreak: ledger.longestStreak,
            badgesUnlocked: ledger.unlockedBadges.count,
            badgesTotal: NestBadgeCatalog.allBadges.count
        )
    }
}

// MARK: - State Models

struct KinSliceData: Identifiable {
    let id = UUID()
    let kinSoulId: UUID
    let kinName: String
    let kinEmoji: String
    let colorSeed: Int
    let momentCount: Int
    let percentage: Double
    let topDeed: String
}

struct DeedBarData: Identifiable {
    let id = UUID()
    let deedId: UUID
    let deedName: String
    let deedIcon: String
    let count: Int
    let fraction: Double         // 0…1 relative to max
}

struct DayHeatCell: Identifiable {
    let id = UUID()
    let date: Date
    let dayLabel: String
    let momentCount: Int
    let intensity: HeatIntensity
}

enum HeatIntensity: Int, Comparable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3
    case blazing = 4

    static func < (lhs: HeatIntensity, rhs: HeatIntensity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var glowColor: Color {
        switch self {
        case .none:    return NestPalette.moonThread.opacity(0.3)
        case .low:     return NestPalette.hearthGold.opacity(0.25)
        case .medium:  return NestPalette.hearthGold.opacity(0.5)
        case .high:    return NestPalette.hearthGold.opacity(0.75)
        case .blazing: return NestPalette.hearthGold
        }
    }
}

enum TeamBalanceLevel: String {
    case balanced = "Balanced"
    case slight   = "Mostly Even"
    case tilted   = "Slightly Tilted"
    case heavy    = "Uneven"
    case solo     = "Solo Mode"
    case unknown  = "—"

    var icon: String {
        switch self {
        case .balanced: return "checkmark.seal.fill"
        case .slight:   return "equal.circle.fill"
        case .tilted:   return "arrow.left.arrow.right"
        case .heavy:    return "exclamationmark.triangle.fill"
        case .solo:     return "person.fill"
        case .unknown:  return "questionmark.circle"
        }
    }

    var tintColor: Color {
        switch self {
        case .balanced: return NestPalette.harmonyMoss
        case .slight:   return NestPalette.hearthGold
        case .tilted:   return NestPalette.candleAmber
        case .heavy:    return NestPalette.nudgeRose
        case .solo:     return NestPalette.duskWhisper
        case .unknown:  return NestPalette.shadowMurmur
        }
    }
}

struct SparkProgressData: Equatable {
    var clanLevel: ClanLevel = .seedling
    var clanEmoji: String = "🌱"
    var clanName: String = "Seedling Nest"
    var nextLevelName: String? = "Sprouting Home"
    var totalSparks: Int = 0
    var progressToNext: Double = 0
    var sparksNeeded: Int = 50
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var badgesUnlocked: Int = 0
    var badgesTotal: Int = 10
}

enum GlancePeriod: String, CaseIterable, Identifiable {
    case week  = "Week"
    case month = "Month"

    var id: String { rawValue }
}

enum GlancePhase {
    case loading
    case ready
    case empty
}
