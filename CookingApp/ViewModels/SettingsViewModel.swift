import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedAllergies: Set<Allergy>
    @Published var selectedDiets: Set<Diet>
    @Published var preferredDifficulties: Set<Difficulty>
    @Published var maxDuration: MaxDuration
    @Published var notificationPreferences: NotificationPreferences

    private let prefs = UserPreferencesManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.selectedAllergies = prefs.dietaryProfile.selectedAllergies
        self.selectedDiets = prefs.dietaryProfile.selectedDiets
        self.preferredDifficulties = prefs.dietaryProfile.preferredDifficulties
        self.maxDuration = prefs.dietaryProfile.maxDuration
        self.notificationPreferences = prefs.notificationPreferences

        Publishers.CombineLatest(
            Publishers.CombineLatest3($selectedAllergies, $selectedDiets, $notificationPreferences),
            Publishers.CombineLatest($preferredDifficulties, $maxDuration)
        )
        .dropFirst()
        .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in await self?.save() }
        }
        .store(in: &cancellables)
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
        if preferredDifficulties.contains(difficulty) {
            preferredDifficulties.remove(difficulty)
        } else {
            preferredDifficulties.insert(difficulty)
        }
    }

    func save() async {
        let profile = DietaryProfile(
            selectedAllergies: selectedAllergies,
            selectedDiets: selectedDiets,
            preferredDifficulties: preferredDifficulties,
            maxDuration: maxDuration
        )

        prefs.dietaryProfile = profile
        prefs.notificationPreferences = notificationPreferences

        NotificationService.shared.scheduleAllNotifications(
            preferences: notificationPreferences,
            recipeName: nil
        )

        try? await FirestoreService.shared.pushDietaryProfile(profile, deviceId: prefs.deviceId)
    }

    func resetOnboarding() {
        NotificationService.shared.cancelAllNotifications()
        prefs.resetOnboarding()
    }
}
