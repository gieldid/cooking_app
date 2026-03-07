import SwiftUI

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
                guard url.scheme == "inkgredients",
                      url.host == "recipe",
                      let recipeId = url.pathComponents.dropFirst().first
                else { return }
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

struct MainTabView: View {
    @StateObject private var homeViewModel = HomeViewModel()

    var body: some View {
        TabView {
            NavigationStack { HomeView(viewModel: homeViewModel) }
                .tabItem {
                    Label("Today", systemImage: "fork.knife")
                }

            NavigationStack { ShoppingListView(homeViewModel: homeViewModel) }
                .tabItem {
                    Label("Shopping", systemImage: "cart")
                }

            NavigationStack { FavouritesView() }
                .tabItem {
                    Label(String(localized: "Favourites"), systemImage: "heart")
                }

            NavigationStack { SettingsView() }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
