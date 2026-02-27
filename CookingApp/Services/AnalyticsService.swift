import FirebaseAnalytics
import SwiftUI

final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    // MARK: - Onboarding funnel

    func trackOnboardingStepViewed(step: Int) {
        let name = stepName(for: step)
        Analytics.logEvent("onboarding_step_viewed", parameters: [
            "step": step,
            "step_name": name
        ])
        logToFirestore(event: "onboarding_step_viewed", params: ["step": step, "stepName": name])
    }

    func trackOnboardingAbandoned(atStep step: Int) {
        let name = stepName(for: step)
        Analytics.logEvent("onboarding_abandoned", parameters: [
            "step": step,
            "step_name": name
        ])
        logToFirestore(event: "onboarding_abandoned", params: ["step": step, "stepName": name])
    }

    func trackOnboardingCompleted() {
        Analytics.logEvent("onboarding_completed", parameters: nil)
        logToFirestore(event: "onboarding_completed")
    }

    // MARK: - Recipe engagement

    func trackRecipeSkipped(recipeId: String, recipeTitle: String) {
        Analytics.logEvent("recipe_skipped", parameters: [
            "recipe_id": recipeId,
            "recipe_title": recipeTitle
        ])
        logToFirestore(event: "recipe_skipped", params: [
            "recipeId": recipeId,
            "recipeTitle": recipeTitle
        ])
    }

    // MARK: - Screen time

    func trackScreenTime(screen: String, durationSeconds: Double) {
        Analytics.logEvent("screen_time", parameters: [
            "screen": screen,
            "duration_seconds": Int(durationSeconds)
        ])
        logToFirestore(event: "screen_time", params: [
            "screen": screen,
            "durationSeconds": Int(durationSeconds)
        ])
    }

    // MARK: - App lifecycle

    func trackAppBackgrounded() {
        Analytics.logEvent("app_backgrounded", parameters: nil)
        logToFirestore(event: "app_backgrounded")
    }

    // MARK: - Private

    private func logToFirestore(event: String, params: [String: Any] = [:]) {
        var data = params
        data["event"] = event
        data["deviceId"] = UserPreferencesManager.shared.deviceId
        FirestoreService.shared.logAnalyticsEvent(data)
    }

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

// MARK: - Screen time modifier

extension View {
    func trackScreenTime(_ screen: String) -> some View {
        modifier(ScreenTimeModifier(screen: screen))
    }
}

private struct ScreenTimeModifier: ViewModifier {
    let screen: String
    @State private var appearTime: Date?

    func body(content: Content) -> some View {
        content
            .onAppear { appearTime = Date() }
            .onDisappear {
                guard let t = appearTime else { return }
                AnalyticsService.shared.trackScreenTime(
                    screen: screen,
                    durationSeconds: Date().timeIntervalSince(t)
                )
                appearTime = nil
            }
    }
}
