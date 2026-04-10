import Foundation

enum RecipeFilter {
    /// Returns true if `recipe` satisfies every constraint in `profile`.
    /// Pass an explicit `weekday` (Calendar.weekday component, 1=Sun…7=Sat)
    /// to override today — useful for unit tests.
    static func matches(
        recipe: Recipe,
        profile: DietaryProfile,
        weekday: Int? = nil
    ) -> Bool {
        // Allergens: recipe must be free of every user allergy
        for allergy in profile.selectedAllergies {
            if !recipe.allergenFree.contains(allergy.rawValue) { return false }
        }

        // Dietary tags: recipe must carry ALL selected diet tags
        if !profile.selectedDiets.isEmpty {
            let recipeTags = Set(recipe.dietaryTags)
            let userDiets = Set(profile.selectedDiets.map { $0.rawValue })
            if !userDiets.isSubset(of: recipeTags) { return false }
        }

        // Resolve per-day overrides vs. global preferences
        let day = weekday ?? Calendar.current.component(.weekday, from: Date())
        let effectiveDifficulties = profile.perDayOverrides[day]?.difficulties
            ?? profile.preferredDifficulties
        let effectiveDuration = profile.perDayOverrides[day]?.maxDuration
            ?? profile.maxDuration

        // Difficulty: skip check if no preference set, or recipe has no difficulty field
        if !effectiveDifficulties.isEmpty, let diff = recipe.difficulty {
            if !effectiveDifficulties.map({ $0.rawValue }).contains(diff) { return false }
        }

        // Duration: recipe total time must be within the limit
        if let maxMinutes = effectiveDuration.minutes, recipe.totalTime > maxMinutes {
            return false
        }

        return true
    }
}
