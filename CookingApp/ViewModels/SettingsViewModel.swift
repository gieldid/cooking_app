import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedAllergies: Set<Allergy>
    @Published var selectedDiets: Set<Diet>
    @Published var notificationPreferences: NotificationPreferences

    private let prefs = UserPreferencesManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.selectedAllergies = prefs.dietaryProfile.selectedAllergies
        self.selectedDiets = prefs.dietaryProfile.selectedDiets
        self.notificationPreferences = prefs.notificationPreferences

        Publishers.CombineLatest3($selectedAllergies, $selectedDiets, $notificationPreferences)
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

    func save() async {
        let profile = DietaryProfile(
            selectedAllergies: selectedAllergies,
            selectedDiets: selectedDiets
        )

        prefs.dietaryProfile = profile
        prefs.notificationPreferences = notificationPreferences

        // Update notifications
        NotificationService.shared.scheduleAllNotifications(
            preferences: notificationPreferences,
            recipeName: nil
        )

        // Push updated profile to Firestore
        try? await FirestoreService.shared.pushDietaryProfile(profile, deviceId: prefs.deviceId)
    }

    func resetOnboarding() {
        NotificationService.shared.cancelAllNotifications()
        prefs.resetOnboarding()
    }
}
