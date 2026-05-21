import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var todayRecipe: Recipe?
    @Published var isLoading = false
    @Published var isSkipping = false
    @Published var errorMessage: String?
    @Published var allFilteredRecipes: [Recipe] = []
    @Published var servingsMultiplier: Int = 1

    private let firestoreService = FirestoreService.shared
    private let prefs = UserPreferencesManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?

    /// Tracks every recipe shown this session; when all of allFilteredRecipes are seen
    /// the next skip fetches a fresh page.
    private var sessionSeenIds: Set<String> = []
    var needsRefetch = false

    init() {
        prefs.$dietaryProfile
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.needsRefetch = true }
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

    func loadTodayRecipe(forceRefresh: Bool = false, bypassCache: Bool = false) {
        guard todayRecipe == nil || forceRefresh else { return }
        loadTask?.cancel()
        loadTask = Task { await performLoad(bypassCache: bypassCache) }
    }

    private func performLoad(bypassCache: Bool = false) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let recipes = try await firestoreService.fetchFilteredRecipes(
                profile: prefs.dietaryProfile,
                bypassCache: bypassCache
            )
            let skipped = prefs.skippedRecipeIds
            allFilteredRecipes = recipes.filter { !skipped.contains($0.id ?? "") }
            sessionSeenIds = []

            if recipes.isEmpty {
                todayRecipe = nil
                errorMessage = String(localized: "error.no_recipes")
            } else {
                if let savedId = prefs.pickedRecipeIdForToday(),
                   let saved = recipes.first(where: { $0.id == savedId }) {
                    if saved.id != todayRecipe?.id {
                        todayRecipe = saved
                        servingsMultiplier = initialServings(for: saved)
                    }
                } else {
                    let dayIndex = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
                    let picked = recipes[dayIndex % recipes.count]
                    applyRecipe(picked)
                }

                if let recipe = todayRecipe {
                    sessionSeenIds.insert(recipe.id ?? "")
                    WatchSessionManager.shared.sendRecipe(recipe)
                }

                NotificationService.shared.scheduleAllNotifications(
                    preferences: prefs.notificationPreferences,
                    recipes: allFilteredRecipes,
                    todayRecipeName: todayRecipe?.title,
                    todayImageURL: todayRecipe?.imageURL
                )
            }
        } catch is CancellationError {
        } catch {
            errorMessage = String(localized: "error.load_failed")
        }
    }

    func skipRecipe() {
        guard let current = todayRecipe else { return }

        AnalyticsService.shared.trackRecipeSkipped(
            recipeId: current.id ?? "unknown",
            recipeTitle: current.title
        )

        // Persist the skip and remove from the in-memory list so it never comes back
        if let id = current.id {
            prefs.addSkippedRecipe(id: id)
            allFilteredRecipes.removeAll { $0.id == id }
            sessionSeenIds.remove(id)
        }

        // Candidates: not current and not yet shown this session
        let candidates = allFilteredRecipes.filter {
            $0.id != current.id && !sessionSeenIds.contains($0.id ?? "")
        }

        if candidates.isEmpty {
            // Every recipe in the current batch has been seen — fetch the next page
            Task { await loadNextPageAndSkip() }
            return
        }

        let recentIds = Set(prefs.recentRecipeIds)
        let preferred = candidates.filter { !recentIds.contains($0.id ?? "") }
        applyRecipe((preferred.isEmpty ? candidates : preferred).randomElement()!)
    }

    private func loadNextPageAndSkip() async {
        guard !isSkipping else { return }
        isSkipping = true
        defer { isSkipping = false }

        do {
            let nextRecipes = try await firestoreService.fetchNextPage(profile: prefs.dietaryProfile)
            let skipped = prefs.skippedRecipeIds
            let newRecipes = nextRecipes.filter { r in
                !allFilteredRecipes.contains(where: { $0.id == r.id }) &&
                !skipped.contains(r.id ?? "")
            }
            allFilteredRecipes.append(contentsOf: newRecipes)

            let recentIds = Set(prefs.recentRecipeIds)
            let preferred = newRecipes.filter { !recentIds.contains($0.id ?? "") }
            let pool = preferred.isEmpty ? newRecipes : preferred
            guard let picked = pool.randomElement() ?? allFilteredRecipes.first(where: { $0.id != todayRecipe?.id }) else { return }
            applyRecipe(picked)
        } catch {
            // Silently fail — user stays on current recipe
        }
    }

    /// Sets the given recipe as today's pick, persists it, and syncs downstream state.
    private func applyRecipe(_ recipe: Recipe) {
        todayRecipe = recipe
        servingsMultiplier = initialServings(for: recipe)
        if let id = recipe.id {
            prefs.savePickedRecipe(id: id)
            sessionSeenIds.insert(id)
        }
        WatchSessionManager.shared.sendRecipe(recipe)
        NotificationService.shared.scheduleAllNotifications(
            preferences: prefs.notificationPreferences,
            recipes: allFilteredRecipes,
            todayRecipeName: recipe.title,
            todayImageURL: recipe.imageURL
        )
    }

    private func initialServings(for recipe: Recipe) -> Int {
        let def = prefs.defaultServings
        return def > 0 ? def : recipe.servings
    }
}
