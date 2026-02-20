import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingContainerView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
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

            NavigationStack { SettingsView() }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
