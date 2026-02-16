import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentPage = 0
    @Published var selectedAllergies: Set<Allergy> = []
    @Published var selectedDiets: Set<Diet> = []
    @Published var notificationPreferences: NotificationPreferences = .default
    @Published var isCompleting = false

    let totalPages = 4

    var canAdvance: Bool {
        currentPage < totalPages - 1
    }

    func nextPage() {
        guard canAdvance else { return }
        currentPage += 1
    }

    func previousPage() {
        guard currentPage > 0 else { return }
        currentPage -= 1
    }

    func toggleAllergy(_ allergy: Allergy) {
        if selectedAllergies.contains(allergy) {
            selectedAllergies.remove(allergy)
        } else {
            selectedAllergies.insert(allergy)
        }
    }

    func toggleDiet(_ diet: Diet) {
        if selectedDiets.contains(diet) {
            selectedDiets.remove(diet)
        } else {
            selectedDiets.insert(diet)
        }
    }

    func completeOnboarding() async {
        isCompleting = true
        defer { isCompleting = false }

        let prefs = UserPreferencesManager.shared
        let profile = DietaryProfile(
            selectedAllergies: selectedAllergies,
            selectedDiets: selectedDiets
        )

        prefs.dietaryProfile = profile
        prefs.notificationPreferences = notificationPreferences

        // Request notification permission and schedule
        let granted = await NotificationService.shared.requestPermission()
        if granted {
            NotificationService.shared.scheduleAllNotifications(
                preferences: notificationPreferences,
                recipeName: nil
            )
        } else {
            prefs.notificationPreferences.isEnabled = false
        }

        // Push dietary profile anonymously to Firestore
        try? await FirestoreService.shared.pushDietaryProfile(profile, deviceId: prefs.deviceId)

        prefs.hasCompletedOnboarding = true
    }
}
