// HearthVault.swift
// Our Days: Easy Now
// Local JSON persistence — no Core Data, no cloud, fully offline

import Foundation

// MARK: - Hearth Vault (Central Data Store)

final class HearthVault: ObservableObject {
    static let shared = HearthVault()

    // MARK: Published Data

    @Published var kinSouls: [KinSoul] = []
    @Published var hearthDeeds: [HearthDeed] = []
    @Published var emberMoments: [EmberMoment] = []
    @Published var sparkLedger: BondSparkLedger = BondSparkLedger()
    @Published var nestPreferences: NestPreferences = NestPreferences()

    // MARK: Onboarding Flag

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: vaultKey("onboarding_done")) }
        set { UserDefaults.standard.set(newValue, forKey: vaultKey("onboarding_done")) }
    }

    // MARK: Private

    private let vaultQueue = DispatchQueue(label: "com.ourdays.vault", qos: .userInitiated)
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = .prettyPrinted
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        loadAllFromDisk()
    }

    // MARK: - File Paths

    private var vaultDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("HearthVault", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func vaultFile(_ name: String) -> URL {
        vaultDirectory.appendingPathComponent("\(name).json")
    }

    private func vaultKey(_ key: String) -> String {
        "com.ourdays.easynow.\(key)"
    }

    // MARK: - Load All

    private func loadAllFromDisk() {
        kinSouls = loadArray(from: "kin_souls") ?? []
        hearthDeeds = loadArray(from: "hearth_deeds") ?? HearthDeedFactory.createDefaults()
        emberMoments = loadArray(from: "ember_moments") ?? []
        sparkLedger = loadObject(from: "spark_ledger") ?? BondSparkLedger()
        nestPreferences = loadObject(from: "nest_preferences") ?? NestPreferences()

        // Ensure deeds exist on first launch
        if hearthDeeds.isEmpty {
            hearthDeeds = HearthDeedFactory.createDefaults()
            saveDeeds()
        }
    }

    // MARK: - Generic Load / Save

    private func loadArray<T: Codable>(from fileName: String) -> [T]? {
        let url = vaultFile(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([T].self, from: data)
        } catch {
            print("🏠 HearthVault: Failed to load \(fileName): \(error)")
            return nil
        }
    }

    private func loadObject<T: Codable>(from fileName: String) -> T? {
        let url = vaultFile(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch {
            print("🏠 HearthVault: Failed to load \(fileName): \(error)")
            return nil
        }
    }

    private func saveArray<T: Codable>(_ items: [T], to fileName: String) {
        vaultQueue.async { [weak self] in
            guard let self else { return }
            do {
                let data = try self.encoder.encode(items)
                try data.write(to: self.vaultFile(fileName), options: .atomic)
            } catch {
                print("🏠 HearthVault: Failed to save \(fileName): \(error)")
            }
        }
    }

    private func saveObject<T: Codable>(_ object: T, to fileName: String) {
        vaultQueue.async { [weak self] in
            guard let self else { return }
            do {
                let data = try self.encoder.encode(object)
                try data.write(to: self.vaultFile(fileName), options: .atomic)
            } catch {
                print("🏠 HearthVault: Failed to save \(fileName): \(error)")
            }
        }
    }

    // MARK: - Kin Souls (Family Members)

    func addKinSoul(_ soul: KinSoul) {
        kinSouls.append(soul)
        saveSouls()
    }

    func updateKinSoul(_ soul: KinSoul) {
        if let idx = kinSouls.firstIndex(where: { $0.id == soul.id }) {
            kinSouls[idx] = soul
            saveSouls()
        }
    }

    func archiveKinSoul(id: UUID) {
        if let idx = kinSouls.firstIndex(where: { $0.id == id }) {
            kinSouls[idx].isArchived = true
            saveSouls()
        }
    }

    var activeKinSouls: [KinSoul] {
        kinSouls.filter { !$0.isArchived }
    }

    private func saveSouls() {
        saveArray(kinSouls, to: "kin_souls")
    }

    // MARK: - Hearth Deeds (Actions)

    func addHearthDeed(_ deed: HearthDeed) {
        hearthDeeds.append(deed)
        saveDeeds()
    }

    func updateHearthDeed(_ deed: HearthDeed) {
        if let idx = hearthDeeds.firstIndex(where: { $0.id == deed.id }) {
            hearthDeeds[idx] = deed
            saveDeeds()
        }
    }

    func archiveHearthDeed(id: UUID) {
        if let idx = hearthDeeds.firstIndex(where: { $0.id == id }) {
            hearthDeeds[idx].isArchived = true
            saveDeeds()
        }
    }

    var activeDeeds: [HearthDeed] {
        hearthDeeds
            .filter { !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private func saveDeeds() {
        saveArray(hearthDeeds, to: "hearth_deeds")
    }

    // MARK: - Ember Moments (Events)

    func logEmberMoment(_ moment: EmberMoment) {
        emberMoments.append(moment)
        saveMoments()
        awardSparksForMoment(moment)
        checkBadgesAfterMoment(moment)
    }

    func updateEmberMoment(_ moment: EmberMoment) {
        if let idx = emberMoments.firstIndex(where: { $0.id == moment.id }) {
            emberMoments[idx] = moment
            saveMoments()
        }
    }

    func deleteEmberMoment(id: UUID) {
        emberMoments.removeAll { $0.id == id }
        saveMoments()
    }

    func toggleGratitude(momentId: UUID, fromKinId: UUID) {
        if let idx = emberMoments.firstIndex(where: { $0.id == momentId }) {
            emberMoments[idx].hasGratitude.toggle()
            emberMoments[idx].gratitudeFrom = emberMoments[idx].hasGratitude ? fromKinId : nil
            saveMoments()

            if emberMoments[idx].hasGratitude {
                checkGratitudeBadge()
            }
        }
    }

    private func saveMoments() {
        saveArray(emberMoments, to: "ember_moments")
    }

    // MARK: Moment Queries

    func momentsForToday() -> [EmberMoment] {
        let todayKey = Date().nestDayKey
        return emberMoments
            .filter { $0.dayKey == todayKey }
            .sorted { $0.happenedAt > $1.happenedAt }
    }

    func momentsForDate(_ date: Date) -> [EmberMoment] {
        let key = date.nestDayKey
        return emberMoments
            .filter { $0.dayKey == key }
            .sorted { $0.happenedAt > $1.happenedAt }
    }

    func momentsForWeek(containing date: Date) -> [EmberMoment] {
        let cal = Calendar.current
        let weekStart = date.startOfWeek
        let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) ?? date
        return emberMoments
            .filter { $0.happenedAt >= weekStart && $0.happenedAt < weekEnd }
            .sorted { $0.happenedAt > $1.happenedAt }
    }

    func momentsForMonth(containing date: Date) -> [EmberMoment] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        guard let monthStart = cal.date(from: comps),
              let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) else {
            return []
        }
        return emberMoments
            .filter { $0.happenedAt >= monthStart && $0.happenedAt < monthEnd }
            .sorted { $0.happenedAt > $1.happenedAt }
    }

    func todayCountForDeed(_ deedId: UUID) -> Int {
        momentsForToday().filter { $0.deedId == deedId }.count
    }

    // MARK: - Spark Ledger (Gamification)

    private func awardSparksForMoment(_ moment: EmberMoment) {
        sparkLedger.totalSparks += 1
        sparkLedger.weeklySparksCurrent += 1
        updateStreak(for: moment.happenedAt)
        updateClanLevel()
        saveLedger()
    }

    private func updateStreak(for date: Date) {
        let today = Date().nestDayKey
        let momentDay = date.nestDayKey

        guard momentDay == today else { return }

        if let lastActive = sparkLedger.lastActiveDate {
            let cal = Calendar.current
            if cal.isDateInYesterday(lastActive) {
                sparkLedger.currentStreak += 1
            } else if !cal.isDateInToday(lastActive) {
                sparkLedger.currentStreak = 1
            }
        } else {
            sparkLedger.currentStreak = 1
        }

        sparkLedger.lastActiveDate = Date()
        sparkLedger.longestStreak = max(sparkLedger.longestStreak, sparkLedger.currentStreak)
    }

    private func updateClanLevel() {
        let total = sparkLedger.totalSparks
        let levels = ClanLevel.allCases.reversed()
        for level in levels {
            if total >= level.sparksRequired {
                sparkLedger.clanLevel = level
                break
            }
        }
    }

    private func saveLedger() {
        saveObject(sparkLedger, to: "spark_ledger")
    }

    // MARK: - Badges

    private func checkBadgesAfterMoment(_ moment: EmberMoment) {
        var changed = false

        // First Ember
        if !hasBadge("first_ember") && emberMoments.count >= 1 {
            unlockBadge("first_ember")
            changed = true
        }

        // Century Mark
        if !hasBadge("century_mark") && emberMoments.count >= 100 {
            unlockBadge("century_mark")
            changed = true
        }

        // Night Owl (after midnight, before 5am)
        let hour = Calendar.current.component(.hour, from: moment.happenedAt)
        if !hasBadge("night_owl") && (hour >= 0 && hour < 5) {
            unlockBadge("night_owl")
            changed = true
        }

        // Early Bird (5am - 6am)
        if !hasBadge("early_bird") && (hour >= 5 && hour < 6) {
            unlockBadge("early_bird")
            changed = true
        }

        // Team Spirit (2 members same day)
        if !hasBadge("team_spirit") {
            let todayMoments = momentsForDate(moment.happenedAt)
            let uniqueKin = Set(todayMoments.map { $0.kinSoulId })
            if uniqueKin.count >= 2 {
                unlockBadge("team_spirit")
                changed = true
            }
        }

        // Week Warrior (7-day streak)
        if !hasBadge("week_warrior") && sparkLedger.currentStreak >= 7 {
            unlockBadge("week_warrior")
            changed = true
        }

        // Bond Blaze (14-day streak)
        if !hasBadge("bond_blaze") && sparkLedger.currentStreak >= 14 {
            unlockBadge("bond_blaze")
            changed = true
        }

        // Mighty Oak level
        if !hasBadge("mighty_oak") && sparkLedger.clanLevel == .oak {
            unlockBadge("mighty_oak")
            changed = true
        }

        if changed {
            saveLedger()
        }
    }

    private func checkGratitudeBadge() {
        if !hasBadge("grateful_heart") {
            unlockBadge("grateful_heart")
            saveLedger()
        }
    }

    private func hasBadge(_ badgeId: String) -> Bool {
        sparkLedger.unlockedBadges.contains { $0.id == badgeId }
    }

    private func unlockBadge(_ badgeId: String) {
        guard var badge = NestBadgeCatalog.allBadges.first(where: { $0.id == badgeId }) else { return }
        badge.unlockedAt = Date()
        sparkLedger.unlockedBadges.append(badge)
    }

    // MARK: - Preferences

    func savePreferences() {
        saveObject(nestPreferences, to: "nest_preferences")
    }

    // MARK: - Weekly Summary Builder

    func buildBondWeave(for date: Date) -> BondWeave {
        let weekMoments = momentsForWeek(containing: date)
        let weekStart = date.startOfWeek
        let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? date

        var contributions: [KinContribution] = []
        let total = weekMoments.count

        for soul in activeKinSouls {
            let soulMoments = weekMoments.filter { $0.kinSoulId == soul.id }
            let count = soulMoments.count
            let pct = total > 0 ? Double(count) / Double(total) * 100 : 0

            // Top deeds for this member
            let deedCounts = Dictionary(grouping: soulMoments, by: { $0.deedId })
            let topDeedIds = deedCounts
                .sorted { $0.value.count > $1.value.count }
                .prefix(3)
                .compactMap { pair in hearthDeeds.first(where: { $0.id == pair.key })?.deedName }

            contributions.append(KinContribution(
                kinSoulId: soul.id,
                momentCount: count,
                percentage: pct,
                topDeeds: topDeedIds
            ))
        }

        // Top deed overall
        let deedCounts = Dictionary(grouping: weekMoments, by: { $0.deedId })
        let topDeedId = deedCounts.max(by: { $0.value.count < $1.value.count })?.key
        let topDeedName = topDeedId.flatMap { id in hearthDeeds.first(where: { $0.id == id })?.deedName }

        // Gentle insight
        let insight = generateGentleInsight(contributions: contributions, total: total)

        return BondWeave(
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalMoments: total,
            kinContributions: contributions,
            topDeed: topDeedName,
            gentleInsight: insight
        )
    }

    private func generateGentleInsight(contributions: [KinContribution], total: Int) -> String {
        guard total > 0 else {
            return "A fresh week awaits — every small moment matters."
        }

        if contributions.count >= 2 {
            let sorted = contributions.sorted { $0.percentage > $1.percentage }
            let diff = sorted[0].percentage - sorted[1].percentage
            if diff < 15 {
                return "Great balance this week — the team is sharing the load well!"
            } else if diff < 35 {
                return "One member carried a bit more — maybe check in on how to share?"
            } else {
                return "The load leaned one way — a gentle conversation could help rebalance."
            }
        }

        return "Every moment logged is a step toward teamwork."
    }

    // MARK: - Statistics

    var totalMomentsAllTime: Int { emberMoments.count }

    var totalGratitudesGiven: Int { emberMoments.filter { $0.hasGratitude }.count }

    func mostActiveDeed() -> HearthDeed? {
        let counts = Dictionary(grouping: emberMoments, by: { $0.deedId })
        guard let topId = counts.max(by: { $0.value.count < $1.value.count })?.key else { return nil }
        return hearthDeeds.first(where: { $0.id == topId })
    }

    // MARK: - Data Export (plain text)

    func exportWeeklySummary(for date: Date) -> String {
        let weave = buildBondWeave(for: date)
        let df = DateFormatter()
        df.dateStyle = .medium

        var lines: [String] = []
        lines.append("═══ Our Days: Easy Now ═══")
        lines.append("Weekly Summary")
        lines.append("\(df.string(from: weave.weekStartDate)) — \(df.string(from: weave.weekEndDate))")
        lines.append("")
        lines.append("Total moments: \(weave.totalMoments)")

        if let topDeed = weave.topDeed {
            lines.append("Most frequent: \(topDeed)")
        }

        lines.append("")
        lines.append("── Team Contributions ──")

        for contrib in weave.kinContributions {
            if let soul = kinSouls.first(where: { $0.id == contrib.kinSoulId }) {
                lines.append("\(soul.spiritEmoji) \(soul.nestName): \(contrib.momentCount) moments (\(String(format: "%.0f", contrib.percentage))%)")
                if !contrib.topDeeds.isEmpty {
                    lines.append("   Top: \(contrib.topDeeds.joined(separator: ", "))")
                }
            }
        }

        if let insight = weave.gentleInsight {
            lines.append("")
            lines.append("💡 \(insight)")
        }

        lines.append("")
        lines.append("Generated with Our Days: Easy Now")

        return lines.joined(separator: "\n")
    }

    // MARK: - Reset (for settings)

    func resetAllData() {
        kinSouls = []
        hearthDeeds = HearthDeedFactory.createDefaults()
        emberMoments = []
        sparkLedger = BondSparkLedger()
        nestPreferences = NestPreferences()
        hasCompletedOnboarding = false

        saveSouls()
        saveDeeds()
        saveMoments()
        saveLedger()
        savePreferences()
    }
}
