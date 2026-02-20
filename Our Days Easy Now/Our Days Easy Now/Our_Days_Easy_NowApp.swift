// OurDaysEasyNowApp.swift
// Our Days: Easy Now
// Family contribution tracker with gamification — dark theme, gold & white accents
// Architecture: MVVM + Coordinator | SwiftUI | iOS 16+ | Local Storage (JSON)

import SwiftUI

// MARK: - Portrait Orientation Lock

class NestOrientationGuard: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

// MARK: - App Entry

@main
struct OurDaysEasyNowApp: App {
    @UIApplicationDelegateAdaptor(NestOrientationGuard.self) var orientationGuard
    @StateObject private var nestCoordinator = NestCoordinator()
    @State private var isSplashComplete = false
    @State private var isOnboardingComplete: Bool = HearthVault.shared.hasCompletedOnboarding

    var body: some Scene {
        WindowGroup {
            AppRootView(
                isSplashComplete: $isSplashComplete,
                isOnboardingComplete: $isOnboardingComplete,
                nestCoordinator: nestCoordinator
            )
        }
    }
}

// MARK: - App Root (observes vault for load errors)

private struct AppRootView: View {
    @ObservedObject private var vault = HearthVault.shared
    @Binding var isSplashComplete: Bool
    @Binding var isOnboardingComplete: Bool
    @ObservedObject var nestCoordinator: NestCoordinator

    var body: some View {
        ZStack {
            NestPalette.emberNight.ignoresSafeArea()

            if vault.loadError != nil {
                    DataLoadErrorView(onRetry: {
                        HearthVault.shared.retryLoad()
                    })
                } else if !isSplashComplete {
                    EmberSplashView(onFinished: {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            isSplashComplete = true
                        }
                    })
                    .transition(.opacity)
                } else if !isOnboardingComplete {
                    KinOnboardingView(onComplete: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isOnboardingComplete = true
                            HearthVault.shared.hasCompletedOnboarding = true
                        }
                    })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    NestTabShell()
                        .environmentObject(nestCoordinator)
                        .transition(.opacity)
                        .onAppear { setupBadgeCallback(coordinator: nestCoordinator) }
                }
        }
        .animation(.easeInOut(duration: 0.5), value: isSplashComplete)
        .animation(.easeInOut(duration: 0.5), value: isOnboardingComplete)
        .animation(.easeInOut(duration: 0.3), value: vault.loadError != nil)
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.xSmall ... .accessibility2)
    }
}

// MARK: - Main Tab Shell

struct NestTabShell: View {
    @EnvironmentObject var coordinator: NestCoordinator
    @State private var chosenHearth: NestTab = .hearth
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
        TabView(selection: $chosenHearth) {
            HearthView()
                .tabItem {
                    Label("Hearth", systemImage: "flame.fill")
                }
                .tag(NestTab.hearth)

            TaleScrollView()
                .tabItem {
                    Label("Tales", systemImage: "scroll.fill")
                }
                .tag(NestTab.taleScroll)

            BondGlanceView()
                .tabItem {
                    Label("Bonds", systemImage: "sparkles")
                }
                .tag(NestTab.bondGlance)

            ClanNookView()
                .tabItem {
                    Label("Clan", systemImage: "house.fill")
                }
                .tag(NestTab.clanNook)
        }
        .tint(NestPalette.hearthGold)
        .onAppear {
            configureTabBarAppearance()
        }

            // Badge confetti overlay
            if let badge = coordinator.badgeConfetti, !reduceMotion {
                BadgeConfettiOverlay(badge: badge)
                    .allowsHitTesting(false)
            }
        }
        .nestSheetRouter()
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(NestPalette.cradleDark)

        let normalAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(NestPalette.duskWhisper)
        ]
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(NestPalette.hearthGold)
        ]

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(NestPalette.duskWhisper)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(NestPalette.hearthGold)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Badge Unlock Callback

private func setupBadgeCallback(coordinator: NestCoordinator) {
    HearthVault.shared.onBadgeUnlocked = { badge in
        coordinator.showBadgeUnlocked(badge: badge)
    }
}

// MARK: - Tab Enum

enum NestTab: String, CaseIterable {
    case hearth
    case taleScroll
    case bondGlance
    case clanNook
}
