// NestCoordinator.swift
// Our Days: Easy Now
// MVVM + Coordinator — central navigation hub for the entire app

import SwiftUI
import Combine

// MARK: - Nest Coordinator

@MainActor
final class NestCoordinator: ObservableObject {

    // MARK: Active Tab

    @Published var activeHearth: NestTab = .hearth

    // MARK: Sheet Navigation

    @Published var activeSheet: NestSheet?
    @Published var isSheetPresented: Bool = false

    // MARK: Toast / Snackbar

    @Published var activeToast: EmberToast?
    @Published var isToastVisible: Bool = false

    // MARK: Alert / Confirmation

    @Published var activeAlert: NestAlert?
    @Published var isAlertPresented: Bool = false

    // MARK: Undo Support

    @Published var undoPayload: UndoEmberPayload?

    private var toastDismissTask: Task<Void, Never>?

    // MARK: - Sheet Navigation

    func presentSheet(_ sheet: NestSheet) {
        activeSheet = sheet
        isSheetPresented = true
    }

    func dismissSheet() {
        isSheetPresented = false
        activeSheet = nil
    }

    // MARK: - Tab Switching

    func switchTo(_ tab: NestTab) {
        withAnimation(.easeInOut(duration: 0.25)) {
            activeHearth = tab
        }
    }

    // MARK: - Quick Actions from Hearth

    func openWhoDid(for deed: HearthDeed) {
        presentSheet(.whoDid(deed: deed))
    }

    func openMomentDetail(_ moment: EmberMoment) {
        presentSheet(.momentDetail(moment: moment))
    }

    func openAddCustomDeed() {
        presentSheet(.addDeed)
    }

    func openAddKinSoul() {
        presentSheet(.addKinSoul)
    }

    func openEditKinSoul(_ soul: KinSoul) {
        presentSheet(.editKinSoul(soul: soul))
    }

    func openEditDeed(_ deed: HearthDeed) {
        presentSheet(.editDeed(deed: deed))
    }

    func openBadgeGallery() {
        presentSheet(.badgeGallery)
    }

    func openExportSummary() {
        presentSheet(.exportSummary)
    }

    func openAvatarPicker() {
        presentSheet(.avatarPicker)
    }

    func openStatsDashboard() {
        presentSheet(.statsDashboard)
    }

    // MARK: - Toast System

    func showToast(_ toast: EmberToast) {
        toastDismissTask?.cancel()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            activeToast = toast
            isToastVisible = true
        }

        toastDismissTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            dismissToast()
        }
    }

    func dismissToast() {
        withAnimation(.easeOut(duration: 0.3)) {
            isToastVisible = false
        }
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            activeToast = nil
        }
    }

    func showMomentLogged(deedName: String, kinName: String) {
        showToast(EmberToast(
            icon: "checkmark.circle.fill",
            message: "\(kinName) — \(deedName)",
            style: .success
        ))
    }

    func showGratitudeSent(toName: String) {
        showToast(EmberToast(
            icon: "heart.fill",
            message: "Thanks sent to \(toName)!",
            style: .gratitude
        ))
    }

    func showBadgeUnlocked(badge: NestBadge) {
        showToast(EmberToast(
            icon: "trophy.fill",
            message: "\(badge.badgeIcon) \(badge.badgeTitle) unlocked!",
            style: .achievement
        ))
    }

    func showUndoToast(moment: EmberMoment, deedName: String) {
        undoPayload = UndoEmberPayload(momentId: moment.id, deedName: deedName)
        showToast(EmberToast(
            icon: "checkmark.circle.fill",
            message: "Logged: \(deedName)",
            style: .success,
            hasUndo: true
        ))
    }

    func performUndo() {
        guard let payload = undoPayload else { return }
        HearthVault.shared.deleteEmberMoment(id: payload.momentId)
        undoPayload = nil
        dismissToast()
        showToast(EmberToast(
            icon: "arrow.uturn.backward",
            message: "Undone",
            style: .neutral
        ))
    }

    // MARK: - Alert System

    func showAlert(_ alert: NestAlert) {
        activeAlert = alert
        isAlertPresented = true
    }

    func confirmResetAllData() {
        showAlert(NestAlert(
            title: "Reset All Data?",
            message: "This will erase every moment, member, and badge. This cannot be undone.",
            primaryLabel: "Reset Everything",
            primaryRole: .destructive,
            onPrimary: {
                HearthVault.shared.resetAllData()
            }
        ))
    }

    func confirmArchiveMember(_ soul: KinSoul) {
        showAlert(NestAlert(
            title: "Archive \(soul.nestName)?",
            message: "Their past moments stay, but they won't appear in new entries.",
            primaryLabel: "Archive",
            primaryRole: .destructive,
            onPrimary: {
                HearthVault.shared.archiveKinSoul(id: soul.id)
            }
        ))
    }

    func confirmDeleteMoment(_ moment: EmberMoment) {
        showAlert(NestAlert(
            title: "Delete this moment?",
            message: "This action cannot be undone.",
            primaryLabel: "Delete",
            primaryRole: .destructive,
            onPrimary: {
                HearthVault.shared.deleteEmberMoment(id: moment.id)
            }
        ))
    }
}

// MARK: - Sheet Types

enum NestSheet: Identifiable {
    case whoDid(deed: HearthDeed)
    case momentDetail(moment: EmberMoment)
    case addDeed
    case editDeed(deed: HearthDeed)
    case addKinSoul
    case editKinSoul(soul: KinSoul)
    case badgeGallery
    case exportSummary
    case avatarPicker
    case statsDashboard

    var id: String {
        switch self {
        case .whoDid(let d):        return "whoDid_\(d.id)"
        case .momentDetail(let m):  return "momentDetail_\(m.id)"
        case .addDeed:              return "addDeed"
        case .editDeed(let d):      return "editDeed_\(d.id)"
        case .addKinSoul:           return "addKinSoul"
        case .editKinSoul(let s):   return "editKinSoul_\(s.id)"
        case .badgeGallery:         return "badgeGallery"
        case .exportSummary:        return "exportSummary"
        case .avatarPicker:         return "avatarPicker"
        case .statsDashboard:       return "statsDashboard"
        }
    }
}

// MARK: - Toast Model

struct EmberToast: Equatable {
    let id: UUID = UUID()
    let icon: String
    let message: String
    let style: EmberToastStyle
    var hasUndo: Bool = false

    static func == (lhs: EmberToast, rhs: EmberToast) -> Bool {
        lhs.id == rhs.id
    }
}

enum EmberToastStyle {
    case success
    case gratitude
    case achievement
    case neutral
    case warning

    var accentColor: SwiftUI.Color {
        switch self {
        case .success:     return NestPalette.harmonyMoss
        case .gratitude:   return NestPalette.bondSpark
        case .achievement: return NestPalette.hearthGold
        case .neutral:     return NestPalette.duskWhisper
        case .warning:     return NestPalette.nudgeRose
        }
    }
}

// MARK: - Alert Model

struct NestAlert: Identifiable {
    let id: UUID = UUID()
    let title: String
    let message: String
    let primaryLabel: String
    var primaryRole: ButtonRole? = nil
    let onPrimary: () -> Void
}

// MARK: - Undo Payload

struct UndoEmberPayload {
    let momentId: UUID
    let deedName: String
}

// MARK: - Toast Overlay View

struct EmberToastOverlay: View {
    @EnvironmentObject var coordinator: NestCoordinator

    var body: some View {
        VStack {
            Spacer()

            if coordinator.isToastVisible, let toast = coordinator.activeToast {
                HStack(spacing: 10) {
                    Image(systemName: toast.icon)
                        .font(.body.bold())
                        .foregroundColor(toast.style.accentColor)

                    Text(toast.message)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(NestPalette.snowfall)
                        .lineLimit(1)

                    Spacer()

                    if toast.hasUndo {
                        Button("Undo") {
                            coordinator.performUndo()
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(NestPalette.hearthGold)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    NestPalette.blanketCharcoal
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(toast.style.accentColor.opacity(0.3), lineWidth: 1)
                        )
                )
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.4), radius: 10, y: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 90)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onTapGesture {
                    coordinator.dismissToast()
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: coordinator.isToastVisible)
        .allowsHitTesting(coordinator.isToastVisible)
    }
}

// MARK: - Alert Modifier

struct NestAlertModifier: ViewModifier {
    @EnvironmentObject var coordinator: NestCoordinator

    func body(content: Content) -> some View {
        content
            .alert(
                coordinator.activeAlert?.title ?? "",
                isPresented: $coordinator.isAlertPresented,
                presenting: coordinator.activeAlert
            ) { alert in
                Button(alert.primaryLabel, role: alert.primaryRole) {
                    alert.onPrimary()
                }
                Button("Cancel", role: .cancel) {}
            } message: { alert in
                Text(alert.message)
            }
    }
}

extension View {
    func nestAlerts() -> some View {
        modifier(NestAlertModifier())
    }
}

// MARK: - Sheet Router View

struct NestSheetRouter: ViewModifier {
    @EnvironmentObject var coordinator: NestCoordinator

    func body(content: Content) -> some View {
        content
            .sheet(item: $coordinator.activeSheet) { sheet in
                sheetContent(for: sheet)
                    .environmentObject(coordinator)
            }
    }

    @ViewBuilder
    private func sheetContent(for sheet: NestSheet) -> some View {
        switch sheet {
        case .whoDid(let deed):
            WhoDidSheet(deed: deed)
        case .momentDetail(let moment):
            MomentDetailSheet(moment: moment)
        case .addDeed:
            AddDeedSheet()
        case .editDeed(let deed):
            EditDeedSheet(deed: deed)
        case .addKinSoul:
            AddKinSoulSheet()
        case .editKinSoul(let soul):
            EditKinSoulSheet(soul: soul)
        case .badgeGallery:
            BadgeGallerySheet()
        case .exportSummary:
            ExportSummarySheet()
        case .avatarPicker:
            AvatarPickerSheet()
        case .statsDashboard:
            StatsDashboardSheet()
        }
    }
}

extension View {
    func nestSheetRouter() -> some View {
        modifier(NestSheetRouter())
    }
}
