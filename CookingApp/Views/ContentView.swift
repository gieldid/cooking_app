import SwiftUI
import StoreKit

/// Wraps a recipe ID so it can be used as an Identifiable sheet item.
private struct RecipeDeepLink: Identifiable {
    let id: String
}

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @ObservedObject private var revenueCat = RevenueCatService.shared
    @State private var deepLinkedRecipe: RecipeDeepLink? = nil
    @State private var showSplash = !ProcessInfo.processInfo.arguments.contains("--screenshots")
    @State private var splashDismissed = false

    private let isScreenshotMode = ProcessInfo.processInfo.arguments.contains("--screenshots")

    var body: some View {
        ZStack {
            Group {
                if !hasCompletedOnboarding && !isScreenshotMode {
                    OnboardingContainerView(splashDismissed: splashDismissed)
                        .transition(.opacity)
                } else if revenueCat.isCheckingEntitlement {
                    // Brief loading state while RevenueCat verifies the entitlement.
                    // Shown only for returning users whose subscription status needs confirming.
                    Color(.systemBackground)
                        .overlay(ProgressView())
                } else if revenueCat.isPremium {
                    MainTabView()
                        .transition(.opacity)
                } else {
                    // Subscription lapsed or skipped — show non-dismissable paywall.
                    NavigationStack {
                        PaywallView(showDismissButton: false)
                    }
                    .transition(.opacity)
                }
            }
            // Only animate going *into* the main app (onboarding → main).
            // The reset direction (main → onboarding) is instant so that MainTabView
            // is immediately removed and its SettingsView onDisappear fires exactly once.
            .animation(hasCompletedOnboarding ? .easeInOut(duration: 0.3) : nil, value: hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.3), value: revenueCat.isPremium)
            .sheet(item: $deepLinkedRecipe) { link in
                SharedRecipeGuestView(recipeId: link.id)
            }
            .onOpenURL { url in
                guard let recipeId = Self.recipeId(from: url) else { return }
                deepLinkedRecipe = RecipeDeepLink(id: recipeId)
            }

            if showSplash {
                SplashScreenView {
                    splashDismissed = true
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

extension ContentView {
    static func recipeId(from url: URL) -> String? {
        let id: String?
        if url.scheme == "inkgredients", url.host == "recipe" {
            // Custom scheme: inkgredients://recipe/<id>
            id = url.pathComponents.dropFirst().first
        } else if url.scheme == "https",
                  url.host == "gieljurriens.nl",
                  url.pathComponents.dropFirst().first == "inkgredients",
                  url.pathComponents.dropFirst(2).first == "recipe" {
            // Universal link: https://gieljurriens.nl/inkgredients/recipe/<id>
            id = url.pathComponents.dropFirst(3).first
        } else {
            return nil
        }
        guard let id, !id.isEmpty, id.count <= 128,
              id.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" })
        else { return nil }
        return id
    }
}

struct MainTabView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    @State private var showNotificationAlert = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView(viewModel: homeViewModel) }
                .tabItem {
                    Label("Today", systemImage: "fork.knife")
                }
                .tag(0)

            NavigationStack { ShoppingListView(homeViewModel: homeViewModel) }
                .tabItem {
                    Label("Shopping", systemImage: "cart")
                }
                .tag(1)

            NavigationStack { FavouritesView() }
                .tabItem {
                    Label(String(localized: "Favourites"), systemImage: "heart")
                }
                .tag(2)

            NavigationStack { SettingsView() }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
        .onChange(of: selectedTab) { newTab in
            if newTab == 0, homeViewModel.needsRefetch {
                homeViewModel.needsRefetch = false
                homeViewModel.loadTodayRecipe(forceRefresh: true)
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            let status = await NotificationService.shared.authorizationStatus()
            if status == .denied {
                showNotificationAlert = true
            }
        }
        .alert("Notifications Disabled", isPresented: $showNotificationAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Later", role: .cancel) {}
        } message: {
            Text("Daily recipe reminders are disabled. Without notifications the app won't remind you to cook. Enable them in Settings to get the most out of the app.")
        }
    }
}
