import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentPage = 0
    @Published var selectedAllergies: Set<Allergy> = []
    @Published var selectedDiets: Set<Diet> = []
    @Published var selectedDifficulties: Set<Difficulty> = []
    @Published var maxDuration: MaxDuration = .any
    @Published var perDayOverrides: [Int: DayOverride] = [:]
    @Published var notificationPreferences: NotificationPreferences = .default
    @Published var isCompleting = false

    let totalPages = 7

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

    func toggleDifficulty(_ difficulty: Difficulty) {
        if selectedDifficulties.contains(difficulty) {
            selectedDifficulties.remove(difficulty)
        } else {
            selectedDifficulties.insert(difficulty)
        }
    }

    func togglePerDayDifficulty(weekday: Int, difficulty: Difficulty) {
        var override = perDayOverrides[weekday] ?? DayOverride(difficulties: selectedDifficulties, maxDuration: maxDuration)
        if override.difficulties.contains(difficulty) {
            override.difficulties.remove(difficulty)
        } else {
            override.difficulties.insert(difficulty)
        }
        perDayOverrides[weekday] = override
    }

    func setPerDayDuration(weekday: Int, duration: MaxDuration) {
        var override = perDayOverrides[weekday] ?? DayOverride(difficulties: selectedDifficulties, maxDuration: maxDuration)
        override.maxDuration = duration
        perDayOverrides[weekday] = override
    }

    func clearPerDayOverride(weekday: Int) {
        perDayOverrides.removeValue(forKey: weekday)
    }

    // MARK: - PerDayPreferencesViewModel
    var globalDifficulties: Set<Difficulty> { selectedDifficulties }

    func completeOnboarding() async {
        isCompleting = true
        defer { isCompleting = false }

        let prefs = UserPreferencesManager.shared
        let profile = DietaryProfile(
            selectedAllergies: selectedAllergies,
            selectedDiets: selectedDiets,
            preferredDifficulties: selectedDifficulties,
            maxDuration: maxDuration,
            perDayOverrides: perDayOverrides
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

        AnalyticsService.shared.trackOnboardingCompleted()
        prefs.hasCompletedOnboarding = true
    }
}
