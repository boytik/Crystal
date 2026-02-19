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
            ZStack {
                NestPalette.emberNight.ignoresSafeArea()

                if !isSplashComplete {
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
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isSplashComplete)
            .animation(.easeInOut(duration: 0.5), value: isOnboardingComplete)
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Main Tab Shell

struct NestTabShell: View {
    @EnvironmentObject var coordinator: NestCoordinator
    @State private var chosenHearth: NestTab = .hearth

    var body: some View {
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

// MARK: - Tab Enum

enum NestTab: String, CaseIterable {
    case hearth
    case taleScroll
    case bondGlance
    case clanNook
}
