import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var todayRecipe: Recipe?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var allFilteredRecipes: [Recipe] = []
    @Published var servingsMultiplier: Int = 1

    private let firestoreService = FirestoreService.shared
    private let prefs = UserPreferencesManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Reload whenever the dietary profile is saved from Settings
        prefs.$dietaryProfile
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.loadTodayRecipe() }
            }
            .store(in: &cancellables)

        prefs.$defaultServings
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] newDefault in
                guard let self else { return }
                self.servingsMultiplier = newDefault > 0 ? newDefault : (self.todayRecipe?.servings ?? 1)
            }
            .store(in: &cancellables)
    }

    func loadTodayRecipe() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let recipes = try await firestoreService.fetchFilteredRecipes(
                profile: prefs.dietaryProfile
            )
            allFilteredRecipes = recipes

            if recipes.isEmpty {
                todayRecipe = nil
                errorMessage = String(localized: "error.no_recipes")
            } else {
                // Pick a recipe based on the day — deterministic per day
                let dayIndex = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
                let picked = recipes[dayIndex % recipes.count]
                if picked.id != todayRecipe?.id {
                    todayRecipe = picked
                    servingsMultiplier = initialServings(for: picked)
                }

                // Update notifications with recipe name
                NotificationService.shared.scheduleAllNotifications(
                    preferences: prefs.notificationPreferences,
                    recipeName: todayRecipe?.title
                )
            }
        } catch is CancellationError {
            // Task was cancelled (view disappeared) — don't show an error
        } catch {
            errorMessage = String(localized: "error.load_failed")
        }
    }

    private func initialServings(for recipe: Recipe) -> Int {
        let def = prefs.defaultServings
        return def > 0 ? def : recipe.servings
    }

    func skipRecipe() {
        guard allFilteredRecipes.count > 1, let current = todayRecipe else { return }

        AnalyticsService.shared.trackRecipeSkipped(
            recipeId: current.id ?? "unknown",
            recipeTitle: current.title
        )

        var filtered = allFilteredRecipes.filter { $0.id != current.id }
        if filtered.isEmpty { filtered = allFilteredRecipes }
        todayRecipe = filtered.randomElement()
        if let recipe = todayRecipe { servingsMultiplier = initialServings(for: recipe) }

        NotificationService.shared.scheduleAllNotifications(
            preferences: prefs.notificationPreferences,
            recipeName: todayRecipe?.title
        )
    }
}
