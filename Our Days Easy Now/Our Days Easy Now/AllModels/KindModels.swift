// KinModels.swift
// Our Days: Easy Now
// Data models — family/hearth naming convention throughout

import Foundation

// MARK: - Family Member (Kin Soul)

struct KinSoul: Codable, Identifiable, Equatable {
    let id: UUID
    var nestName: String           // display name
    var kinRole: KinRole           // family role
    var spiritEmoji: String        // avatar emoji
    var colorSeed: Int             // index into NestPalette.kinColors
    var joinedAt: Date
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        nestName: String,
        kinRole: KinRole = .parent,
        spiritEmoji: String = "🧡",
        colorSeed: Int = 0,
        joinedAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.nestName = nestName
        self.kinRole = kinRole
        self.spiritEmoji = spiritEmoji
        self.colorSeed = colorSeed
        self.joinedAt = joinedAt
        self.isArchived = isArchived
    }
}

enum KinRole: String, Codable, CaseIterable, Identifiable {
    case parent     = "Parent"
    case grandparent = "Grandparent"
    case nanny      = "Nanny"
    case sibling    = "Sibling"
    case other      = "Other"

    var id: String { rawValue }

    var spiritIcon: String {
        switch self {
        case .parent:      return "heart.fill"
        case .grandparent: return "leaf.fill"
        case .nanny:       return "star.fill"
        case .sibling:     return "person.2.fill"
        case .other:       return "sparkle"
        }
    }
}

// MARK: - Quick Action (Hearth Deed)

struct HearthDeed: Codable, Identifiable, Equatable {
    let id: UUID
    var deedName: String           // e.g. "Bathed", "Walked"
    var deedIcon: String           // SF Symbol name
    var deedDomain: DeedDomain     // care vs household
    var sortOrder: Int
    var isArchived: Bool
    var isDefault: Bool            // pre-built or custom

    init(
        id: UUID = UUID(),
        deedName: String,
        deedIcon: String = "hands.sparkles.fill",
        deedDomain: DeedDomain = .care,
        sortOrder: Int = 0,
        isArchived: Bool = false,
        isDefault: Bool = true
    ) {
        self.id = id
        self.deedName = deedName
        self.deedIcon = deedIcon
        self.deedDomain = deedDomain
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.isDefault = isDefault
    }
}

enum DeedDomain: String, Codable, CaseIterable, Identifiable {
    case care      = "Care"
    case household = "Household"
    case custom    = "Custom"

    var id: String { rawValue }

    var tinyIcon: String {
        switch self {
        case .care:      return "heart.circle.fill"
        case .household: return "house.circle.fill"
        case .custom:    return "star.circle.fill"
        }
    }
}

// MARK: - Event (Ember Moment)

struct EmberMoment: Codable, Identifiable, Equatable {
    let id: UUID
    var deedId: UUID               // which HearthDeed
    var kinSoulId: UUID            // who did it
    var happenedAt: Date           // when it happened
    var loggedAt: Date             // when it was logged
    var tinyNote: String?          // optional short note
    var hasGratitude: Bool         // "thank you" reaction
    var gratitudeFrom: UUID?       // who said thanks

    init(
        id: UUID = UUID(),
        deedId: UUID,
        kinSoulId: UUID,
        happenedAt: Date = Date(),
        loggedAt: Date = Date(),
        tinyNote: String? = nil,
        hasGratitude: Bool = false,
        gratitudeFrom: UUID? = nil
    ) {
        self.id = id
        self.deedId = deedId
        self.kinSoulId = kinSoulId
        self.happenedAt = happenedAt
        self.loggedAt = loggedAt
        self.tinyNote = tinyNote
        self.hasGratitude = hasGratitude
        self.gratitudeFrom = gratitudeFrom
    }
}

// MARK: - Weekly Summary (Bond Weave)

struct BondWeave: Codable, Identifiable {
    let id: UUID
    var weekStartDate: Date
    var weekEndDate: Date
    var totalMoments: Int
    var kinContributions: [KinContribution]
    var topDeed: String?
    var gentleInsight: String?

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        weekEndDate: Date,
        totalMoments: Int = 0,
        kinContributions: [KinContribution] = [],
        topDeed: String? = nil,
        gentleInsight: String? = nil
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.totalMoments = totalMoments
        self.kinContributions = kinContributions
        self.topDeed = topDeed
        self.gentleInsight = gentleInsight
    }
}

struct KinContribution: Codable, Identifiable, Equatable {
    let id: UUID
    var kinSoulId: UUID
    var momentCount: Int
    var percentage: Double
    var topDeeds: [String]         // top 3 deed names

    init(
        id: UUID = UUID(),
        kinSoulId: UUID,
        momentCount: Int = 0,
        percentage: Double = 0,
        topDeeds: [String] = []
    ) {
        self.id = id
        self.kinSoulId = kinSoulId
        self.momentCount = momentCount
        self.percentage = percentage
        self.topDeeds = topDeeds
    }
}

// MARK: - Gamification: Bond Spark (Points)

struct BondSparkLedger: Codable {
    var totalSparks: Int
    var currentStreak: Int          // consecutive days with at least 1 moment
    var longestStreak: Int
    var lastActiveDate: Date?
    var clanLevel: ClanLevel
    var unlockedBadges: [NestBadge]
    var weeklySparkGoal: Int
    var weeklySparksCurrent: Int

    init(
        totalSparks: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastActiveDate: Date? = nil,
        clanLevel: ClanLevel = .seedling,
        unlockedBadges: [NestBadge] = [],
        weeklySparkGoal: Int = 30,
        weeklySparksCurrent: Int = 0
    ) {
        self.totalSparks = totalSparks
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActiveDate = lastActiveDate
        self.clanLevel = clanLevel
        self.unlockedBadges = unlockedBadges
        self.weeklySparkGoal = weeklySparkGoal
        self.weeklySparksCurrent = weeklySparksCurrent
    }
}

// MARK: - Clan Levels

enum ClanLevel: String, Codable, CaseIterable {
    case seedling    = "Seedling Nest"
    case sprout      = "Sprouting Home"
    case sapling     = "Sapling Circle"
    case bloom       = "Blooming Bond"
    case oak         = "Mighty Oak Clan"
    case ancientTree = "Ancient Tree"

    var icon: String {
        switch self {
        case .seedling:    return "🌱"
        case .sprout:      return "🌿"
        case .sapling:     return "🌳"
        case .bloom:       return "🌸"
        case .oak:         return "🏡"
        case .ancientTree: return "✨"
        }
    }

    var sparksRequired: Int {
        switch self {
        case .seedling:    return 0
        case .sprout:      return 50
        case .sapling:     return 150
        case .bloom:       return 400
        case .oak:         return 800
        case .ancientTree: return 1500
        }
    }

    var nextLevel: ClanLevel? {
        let all = ClanLevel.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }

    var progressToNext: (current: Int, needed: Int)? {
        guard let next = nextLevel else { return nil }
        return (sparksRequired, next.sparksRequired)
    }
}

// MARK: - Badges / Achievements (Nest Badge)

struct NestBadge: Codable, Identifiable, Equatable {
    let id: String                 // unique key like "first_moment"
    var badgeTitle: String
    var badgeIcon: String          // emoji
    var badgeDesc: String
    var unlockedAt: Date?

    var isUnlocked: Bool { unlockedAt != nil }
}

enum NestBadgeCatalog {
    static let allBadges: [NestBadge] = [
        NestBadge(
            id: "first_ember",
            badgeTitle: "First Ember",
            badgeIcon: "🔥",
            badgeDesc: "Logged your very first moment"
        ),
        NestBadge(
            id: "team_spirit",
            badgeTitle: "Team Spirit",
            badgeIcon: "🤝",
            badgeDesc: "Two family members logged on the same day"
        ),
        NestBadge(
            id: "week_warrior",
            badgeTitle: "Week Warrior",
            badgeIcon: "⚔️",
            badgeDesc: "Logged at least one moment every day for a week"
        ),
        NestBadge(
            id: "grateful_heart",
            badgeTitle: "Grateful Heart",
            badgeIcon: "💛",
            badgeDesc: "Sent your first gratitude spark"
        ),
        NestBadge(
            id: "century_mark",
            badgeTitle: "Century Mark",
            badgeIcon: "💯",
            badgeDesc: "Reached 100 total moments"
        ),
        NestBadge(
            id: "night_owl",
            badgeTitle: "Night Owl",
            badgeIcon: "🦉",
            badgeDesc: "Logged a moment after midnight"
        ),
        NestBadge(
            id: "early_bird",
            badgeTitle: "Early Bird",
            badgeIcon: "🐦",
            badgeDesc: "Logged a moment before 6 AM"
        ),
        NestBadge(
            id: "all_hands",
            badgeTitle: "All Hands",
            badgeIcon: "🙌",
            badgeDesc: "Every family member contributed this week"
        ),
        NestBadge(
            id: "bond_blaze",
            badgeTitle: "Bond Blaze",
            badgeIcon: "🌟",
            badgeDesc: "Reached a 14-day streak"
        ),
        NestBadge(
            id: "mighty_oak",
            badgeTitle: "Mighty Oak",
            badgeIcon: "🏡",
            badgeDesc: "Reached the Mighty Oak clan level"
        ),
    ]
}

// MARK: - Default Deeds Factory

enum HearthDeedFactory {
    static func createDefaults() -> [HearthDeed] {
        [
            HearthDeed(deedName: "Bathed",    deedIcon: "drop.fill",             deedDomain: .care,      sortOrder: 0),
            HearthDeed(deedName: "Walked",    deedIcon: "figure.walk",           deedDomain: .care,      sortOrder: 1),
            HearthDeed(deedName: "Put to Bed",deedIcon: "moon.zzz.fill",         deedDomain: .care,      sortOrder: 2),
            HearthDeed(deedName: "Read",      deedIcon: "book.fill",             deedDomain: .care,      sortOrder: 3),
            HearthDeed(deedName: "Played",    deedIcon: "puzzlepiece.fill",      deedDomain: .care,      sortOrder: 4),
            HearthDeed(deedName: "Cooked",    deedIcon: "frying.pan.fill",       deedDomain: .household, sortOrder: 5),
            HearthDeed(deedName: "Dishes",    deedIcon: "cup.and.saucer.fill",   deedDomain: .household, sortOrder: 6),
            HearthDeed(deedName: "Cleaned",   deedIcon: "sparkles",              deedDomain: .household, sortOrder: 7),
            HearthDeed(deedName: "Laundry",   deedIcon: "washer.fill",           deedDomain: .household, sortOrder: 8),
            HearthDeed(deedName: "Shopping",  deedIcon: "cart.fill",             deedDomain: .household, sortOrder: 9),
        ]
    }
}

// MARK: - App Settings (Nest Preferences)

struct NestPreferences: Codable {
    var softModeEnabled: Bool       // gentle summaries without comparisons
    var userAvatarEmoji: String     // user's chosen emoji avatar
    var weekStartsOnMonday: Bool
    var dailyReminderEnabled: Bool
    var sparkSoundEnabled: Bool     // play sound on logging

    init(
        softModeEnabled: Bool = true,
        userAvatarEmoji: String = "🏠",
        weekStartsOnMonday: Bool = true,
        dailyReminderEnabled: Bool = false,
        sparkSoundEnabled: Bool = true
    ) {
        self.softModeEnabled = softModeEnabled
        self.userAvatarEmoji = userAvatarEmoji
        self.weekStartsOnMonday = weekStartsOnMonday
        self.dailyReminderEnabled = dailyReminderEnabled
        self.sparkSoundEnabled = sparkSoundEnabled
    }
}

// MARK: - Filter State (Tale Filter)

struct TaleFilter: Equatable {
    var period: TalePeriod = .day
    var selectedKinIds: Set<UUID> = []
    var selectedDeedIds: Set<UUID> = []
    var selectedDomain: DeedDomain? = nil
    var searchQuery: String = ""

    var isActive: Bool {
        !selectedKinIds.isEmpty || !selectedDeedIds.isEmpty || selectedDomain != nil || !searchQuery.isEmpty
    }

    mutating func clearAll() {
        selectedKinIds.removeAll()
        selectedDeedIds.removeAll()
        selectedDomain = nil
        searchQuery = ""
    }
}

enum TalePeriod: String, CaseIterable, Identifiable {
    case day   = "Day"
    case week  = "Week"
    case month = "Month"

    var id: String { rawValue }
}

// MARK: - Helpers

extension EmberMoment {
    var dayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: happenedAt)
    }
}

extension Date {
    var nestDayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var startOfWeek: Date {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: components) ?? self
    }

    var shortTimeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: self)
    }

    var friendlyDayString: String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: self)
    }
}
