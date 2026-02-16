import SwiftUI

struct ContentView: View {
    @ObservedObject private var prefs = UserPreferencesManager.shared

    var body: some View {
        if prefs.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingContainerView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "fork.knife")
                }

            ShoppingListView()
                .tabItem {
                    Label("Shopping", systemImage: "cart")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
