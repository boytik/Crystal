// TaleScrollViewModel.swift
// Our Days: Easy Now
// ViewModel for the Tale Scroll (Feed) tab — separated from View per architecture rules

import SwiftUI
import Combine

// MARK: - Tale Scroll ViewModel

@MainActor
final class TaleScrollViewModel: ObservableObject {

    // MARK: Published State

    @Published var groupedTales: [TaleDayGroup] = []
    @Published var filter: TaleFilter = TaleFilter()
    @Published var availableKin: [KinSoul] = []
    @Published var availableDeeds: [HearthDeed] = []
    @Published var viewPhase: TalePhase = .loading
    @Published var totalCount: Int = 0
    @Published var gratitudeCount: Int = 0
    @Published var showFilterBar: Bool = false

    // Search
    @Published var searchText: String = ""

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
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildTales()
            }
            .store(in: &cancellables)

        // Search debounce
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.filter.searchQuery = query
                self?.rebuildTales()
            }
            .store(in: &cancellables)
    }

    // MARK: - Load

    func loadTales() {
        viewPhase = .loading
        availableKin = vault.activeKinSouls
        availableDeeds = vault.activeDeeds

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.rebuildTales()
            withAnimation(.easeOut(duration: 0.3)) {
                self?.viewPhase = .ready
            }
        }
    }

    // MARK: - Rebuild

    private func rebuildTales() {
        availableKin = vault.activeKinSouls
        availableDeeds = vault.activeDeeds

        // 1. Get moments for period
        var moments = momentsForPeriod()

        // 2. Apply kin filter
        if !filter.selectedKinIds.isEmpty {
            moments = moments.filter { filter.selectedKinIds.contains($0.kinSoulId) }
        }

        // 3. Apply deed filter
        if !filter.selectedDeedIds.isEmpty {
            moments = moments.filter { filter.selectedDeedIds.contains($0.deedId) }
        }

        // 4. Apply domain filter
        if let domain = filter.selectedDomain {
            let domainDeedIds = Set(vault.hearthDeeds.filter { $0.deedDomain == domain }.map { $0.id })
            moments = moments.filter { domainDeedIds.contains($0.deedId) }
        }

        // 5. Apply search
        if !filter.searchQuery.isEmpty {
            let query = filter.searchQuery.lowercased()
            moments = moments.filter { moment in
                let soul = vault.kinSouls.first(where: { $0.id == moment.kinSoulId })
                let deed = vault.hearthDeeds.first(where: { $0.id == moment.deedId })
                let nameMatch = soul?.nestName.lowercased().contains(query) ?? false
                let deedMatch = deed?.deedName.lowercased().contains(query) ?? false
                let noteMatch = moment.tinyNote?.lowercased().contains(query) ?? false
                return nameMatch || deedMatch || noteMatch
            }
        }

        // 6. Group by day
        let sorted = moments.sorted { $0.happenedAt > $1.happenedAt }
        let grouped = Dictionary(grouping: sorted) { $0.happenedAt.friendlyDayString }

        // Build ordered groups (preserve chronological day order)
        var dayGroups: [TaleDayGroup] = []
        var seenDays: Set<String> = []

        for moment in sorted {
            let dayLabel = moment.happenedAt.friendlyDayString
            guard !seenDays.contains(dayLabel) else { continue }
            seenDays.insert(dayLabel)

            let dayMoments = grouped[dayLabel] ?? []
            let rows = dayMoments.map { buildRow(from: $0) }

            dayGroups.append(TaleDayGroup(
                dayLabel: dayLabel,
                date: moment.happenedAt,
                moments: rows
            ))
        }

        // Update state
        totalCount = sorted.count
        gratitudeCount = sorted.filter { $0.hasGratitude }.count
        groupedTales = dayGroups

        if groupedTales.isEmpty && viewPhase != .loading {
            viewPhase = filter.isActive ? .filtered : .empty
        } else if viewPhase != .loading {
            viewPhase = .ready
        }
    }

    private func momentsForPeriod() -> [EmberMoment] {
        switch filter.period {
        case .day:
            return vault.momentsForToday()
        case .week:
            return vault.momentsForWeek(containing: Date())
        case .month:
            return vault.momentsForMonth(containing: Date())
        }
    }

    private func buildRow(from moment: EmberMoment) -> TaleMomentRow {
        let soul = vault.kinSouls.first(where: { $0.id == moment.kinSoulId })
        let deed = vault.hearthDeeds.first(where: { $0.id == moment.deedId })
        return TaleMomentRow(
            moment: moment,
            kinName: soul?.nestName ?? "Unknown",
            kinEmoji: soul?.spiritEmoji ?? "❓",
            kinColorSeed: soul?.colorSeed ?? 0,
            deedName: deed?.deedName ?? "Unknown",
            deedIcon: deed?.deedIcon ?? "questionmark",
            deedDomain: deed?.deedDomain ?? .custom,
            timeString: moment.happenedAt.shortTimeString,
            hasGratitude: moment.hasGratitude,
            tinyNote: moment.tinyNote
        )
    }

    // MARK: - Filter Actions

    func setPeriod(_ period: TalePeriod) {
        withAnimation(.easeInOut(duration: 0.25)) {
            filter.period = period
        }
        rebuildTales()
    }

    func toggleKinFilter(_ kinId: UUID) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if filter.selectedKinIds.contains(kinId) {
                filter.selectedKinIds.remove(kinId)
            } else {
                filter.selectedKinIds.insert(kinId)
            }
        }
        rebuildTales()
    }

    func toggleDeedFilter(_ deedId: UUID) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if filter.selectedDeedIds.contains(deedId) {
                filter.selectedDeedIds.remove(deedId)
            } else {
                filter.selectedDeedIds.insert(deedId)
            }
        }
        rebuildTales()
    }

    func setDomainFilter(_ domain: DeedDomain?) {
        withAnimation(.easeInOut(duration: 0.2)) {
            filter.selectedDomain = (filter.selectedDomain == domain) ? nil : domain
        }
        rebuildTales()
    }

    func clearAllFilters() {
        withAnimation(.easeInOut(duration: 0.25)) {
            filter.clearAll()
            searchText = ""
        }
        rebuildTales()
    }

    func toggleFilterBar() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showFilterBar.toggle()
        }
    }

    // MARK: - Moment Actions

    func toggleGratitude(momentId: UUID) {
        let firstSoul = vault.activeKinSouls.first
        guard let soulId = firstSoul?.id else { return }
        vault.toggleGratitude(momentId: momentId, fromKinId: soulId)
    }

    func deleteMoment(_ momentId: UUID) {
        withAnimation(.easeOut(duration: 0.25)) {
            vault.deleteEmberMoment(id: momentId)
        }
    }
}

// MARK: - State Models

struct TaleDayGroup: Identifiable {
    let id = UUID()
    let dayLabel: String
    let date: Date
    let moments: [TaleMomentRow]

    var momentCount: Int { moments.count }
}

struct TaleMomentRow: Identifiable {
    let moment: EmberMoment
    let kinName: String
    let kinEmoji: String
    let kinColorSeed: Int
    let deedName: String
    let deedIcon: String
    let deedDomain: DeedDomain
    let timeString: String
    let hasGratitude: Bool
    let tinyNote: String?

    var id: UUID { moment.id }
}

enum TalePhase {
    case loading
    case ready
    case empty
    case filtered  // has filters but no results
}
