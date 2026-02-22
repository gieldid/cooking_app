import FirebaseAnalytics

final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    // MARK: - Onboarding funnel

    func trackOnboardingStepViewed(step: Int) {
        Analytics.logEvent("onboarding_step_viewed", parameters: [
            "step": step,
            "step_name": stepName(for: step)
        ])
    }

    func trackOnboardingAbandoned(atStep step: Int) {
        Analytics.logEvent("onboarding_abandoned", parameters: [
            "step": step,
            "step_name": stepName(for: step)
        ])
    }

    func trackOnboardingCompleted() {
        Analytics.logEvent("onboarding_completed", parameters: nil)
    }

    // MARK: - Private

    private func stepName(for step: Int) -> String {
        switch step {
        case 0: return "welcome"
        case 1: return "allergies"
        case 2: return "dietary_preferences"
        case 3: return "recipe_preferences"
        case 4: return "notifications"
        case 5: return "subscription"
        default: return "unknown"
        }
    }
}
