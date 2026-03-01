import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.scenePhase) private var scenePhase
    var splashDismissed: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<viewModel.totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index <= viewModel.currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(viewModel.currentPage + 1) of \(viewModel.totalPages)")

            TabView(selection: $viewModel.currentPage) {
                WelcomeView(viewModel: viewModel, splashDismissed: splashDismissed)
                    .tag(0)
                AllergiesView(viewModel: viewModel)
                    .tag(1)
                DietaryPreferencesView(viewModel: viewModel)
                    .tag(2)
                RecipePreferencesView(viewModel: viewModel)
                    .tag(3)
                NotificationSetupView(viewModel: viewModel)
                    .tag(4)
                TrialReminderView(viewModel: viewModel)
                    .tag(5)
                SubscriptionView(viewModel: viewModel)
                    .tag(6)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentPage)
        }
        .onAppear {
            AnalyticsService.shared.trackOnboardingStepViewed(step: 0)
        }
        .onChange(of: viewModel.currentPage) { newPage in
            AnalyticsService.shared.trackOnboardingStepViewed(step: newPage)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                AnalyticsService.shared.trackOnboardingAbandoned(atStep: viewModel.currentPage)
            }
        }
    }
}
