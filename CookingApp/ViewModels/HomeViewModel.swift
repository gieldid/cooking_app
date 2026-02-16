import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var todayRecipe: Recipe?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var allFilteredRecipes: [Recipe] = []

    private let firestoreService = FirestoreService.shared
    private let prefs = UserPreferencesManager.shared

    func loadTodayRecipe() async {
        isLoading = true
        errorMessage = nil

        do {
            let recipes = try await firestoreService.fetchFilteredRecipes(
                profile: prefs.dietaryProfile
            )
            allFilteredRecipes = recipes

            if recipes.isEmpty {
                todayRecipe = nil
                errorMessage = "No recipes match your dietary profile. Try adjusting your preferences in Settings."
            } else {
                // Pick a recipe based on the day — deterministic per day
                let dayIndex = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
                todayRecipe = recipes[dayIndex % recipes.count]

                // Update notifications with recipe name
                NotificationService.shared.scheduleAllNotifications(
                    preferences: prefs.notificationPreferences,
                    recipeName: todayRecipe?.title
                )
            }
        } catch {
            errorMessage = "Failed to load recipes. Check your internet connection."
        }

        isLoading = false
    }

    func skipRecipe() {
        guard allFilteredRecipes.count > 1, let current = todayRecipe else { return }
        var filtered = allFilteredRecipes.filter { $0.id != current.id }
        if filtered.isEmpty { filtered = allFilteredRecipes }
        todayRecipe = filtered.randomElement()

        NotificationService.shared.scheduleAllNotifications(
            preferences: prefs.notificationPreferences,
            recipeName: todayRecipe?.title
        )
    }
}
