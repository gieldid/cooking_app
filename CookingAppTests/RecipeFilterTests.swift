import XCTest
@testable import CookingApp

final class RecipeFilterTests: XCTestCase {

    // MARK: - Helpers

    /// Build a minimal Recipe from a plain dictionary (avoids needing a live Firestore decoder).
    private func makeRecipe(
        allergenFree: [String] = [],
        dietaryTags: [String] = [],
        difficulty: String? = nil,
        prepTime: Int = 10,
        cookTime: Int = 10
    ) throws -> Recipe {
        var dict: [String: Any] = [
            "title": "Test Recipe",
            "description": "A test recipe",
            "ingredients": [],
            "steps": [],
            "dietaryTags": dietaryTags,
            "allergenFree": allergenFree,
            "prepTime": prepTime,
            "cookTime": cookTime,
            "servings": 2
        ]
        if let d = difficulty { dict["difficulty"] = d }
        let data = try JSONSerialization.data(withJSONObject: dict)
        return try JSONDecoder().decode(Recipe.self, from: data)
    }

    private func profile(
        allergies: Set<Allergy> = [],
        diets: Set<Diet> = [],
        difficulties: Set<Difficulty> = [],
        maxDuration: MaxDuration = .any,
        perDayOverrides: [Int: DayOverride] = [:]
    ) -> DietaryProfile {
        DietaryProfile(
            selectedAllergies: allergies,
            selectedDiets: diets,
            preferredDifficulties: difficulties,
            maxDuration: maxDuration,
            perDayOverrides: perDayOverrides
        )
    }

    // MARK: - Empty profile

    func testEmptyProfileMatchesAnyRecipe() throws {
        let recipe = try makeRecipe()
        XCTAssertTrue(RecipeFilter.matches(recipe: recipe, profile: .empty))
    }

    // MARK: - Allergen filtering

    func testRecipeExcludedWhenAllergenNotFree() throws {
        let recipe = try makeRecipe(allergenFree: ["nuts"])
        let p = profile(allergies: [.dairy])  // user allergic to dairy, recipe only free of nuts
        XCTAssertFalse(RecipeFilter.matches(recipe: recipe, profile: p))
    }

    func testRecipeIncludedWhenAllUserAllergiesCovered() throws {
        let recipe = try makeRecipe(allergenFree: ["nuts", "dairy", "gluten"])
        let p = profile(allergies: [.nuts, .dairy])
        XCTAssertTrue(RecipeFilter.matches(recipe: recipe, profile: p))
    }

    func testRecipeExcludedForOneOfSeveralAllergies() throws {
        let recipe = try makeRecipe(allergenFree: ["nuts"])
        let p = profile(allergies: [.nuts, .dairy])  // dairy not covered
        XCTAssertFalse(RecipeFilter.matches(recipe: recipe, profile: p))
    }

    func testRecipeWithNoAllergenFreeStillMatchesUserWithNoAllergies() throws {
        let recipe = try makeRecipe(allergenFree: [])
        XCTAssertTrue(RecipeFilter.matches(recipe: recipe, profile: .empty))
    }

    // MARK: - Diet filtering

    func testRecipeExcludedWhenMissingRequiredDietTag() throws {
        let recipe = try makeRecipe(dietaryTags: ["vegetarian"])
        let p = profile(diets: [.vegan])  // vegan tag missing
        XCTAssertFalse(RecipeFilter.matches(recipe: recipe, profile: p))
    }

    func testRecipeIncludedWhenAllDietTagsPresent() throws {
        let recipe = try makeRecipe(dietaryTags: ["vegan", "glutenFree", "dairyFree"])
        let p = profile(diets: [.vegan, .glutenFree])
        XCTAssertTrue(RecipeFilter.matches(recipe: recipe, profile: p))
    }

    func testRecipeIncludedWhenNoDietsSelected() throws {
        let recipe = try makeRecipe(dietaryTags: [])
        XCTAssertTrue(RecipeFilter.matches(recipe: recipe, profile: .empty))
    }

    // MARK: - Difficulty filtering

    func testRecipeExcludedWhenDifficultyDoesNotMatch() throws {
        let recipe = try makeRecipe(difficulty: "hard")
        let p = profile(difficulties: [.easy, .medium])
        XCTAssertFalse(RecipeFilter.matches(recipe: recipe, profile: p))
    }

    func testRecipeIncludedWhenDifficultyMatches() throws {
        let recipe = try makeRecipe(difficulty: "easy")
        let p = profile(difficulties: [.easy, .medium])
        XCTAssertTrue(RecipeFilter.matches(recipe: recipe, profile: p))
    }

    func testRecipeWithoutDifficultyAlwaysIncluded() throws {
        let recipe = try makeRecipe(difficulty: nil)
        let p = profile(difficulties: [.easy])
        XCTAssertTrue(RecipeFilter.matches(recipe: recipe, profile: p))
    }

    func testNoDifficultyPreferenceIncludesAllDifficulties() throws {
        let hard = try makeRecipe(difficulty: "hard")
        XCTAssertTrue(RecipeFilter.matches(recipe: hard, profile: .empty))
    }

    // MARK: - Duration filtering

    func testRecipeExcludedWhenTooLong() throws {
        let recipe = try makeRecipe(prepTime: 20, cookTime: 45)  // 65 min
        let p = profile(maxDuration: .sixty)
        XCTAssertFalse(RecipeFilter.matches(recipe: recipe, profile: p))
    }

    func testRecipeIncludedWhenExactlyAtLimit() throws {
        let recipe = try makeRecipe(prepTime: 30, cookTime: 30)  // 60 min exactly
        let p = profile(maxDuration: .sixty)
        XCTAssertTrue(RecipeFilter.matches(recipe: recipe, profile: p))
    }

    func testRecipeIncludedWhenBelowLimit() throws {
        let recipe = try makeRecipe(prepTime: 10, cookTime: 15)  // 25 min
        let p = profile(maxDuration: .thirty)
        XCTAssertTrue(RecipeFilter.matches(recipe: recipe, profile: p))
    }

    func testAnyDurationNeverFilters() throws {
        let recipe = try makeRecipe(prepTime: 60, cookTime: 60)  // 120 min
        let p = profile(maxDuration: .any)
        XCTAssertTrue(RecipeFilter.matches(recipe: recipe, profile: p))
    }

    // MARK: - Per-day overrides

    func testPerDayOverrideOverridesGlobalDifficulty() throws {
        let recipe = try makeRecipe(difficulty: "hard")
        let override = DayOverride(difficulties: [.hard], maxDuration: .any)
        let p = profile(difficulties: [.easy], perDayOverrides: [2: override])  // weekday 2 = Monday
        // Global says easy only, but Monday override allows hard
        XCTAssertTrue(RecipeFilter.matches(recipe: recipe, profile: p, weekday: 2))
    }

    func testPerDayOverrideDoesNotAffectOtherDays() throws {
        let recipe = try makeRecipe(difficulty: "hard")
        let override = DayOverride(difficulties: [.hard], maxDuration: .any)
        let p = profile(difficulties: [.easy], perDayOverrides: [2: override])
        // Tuesday (3) uses global preference which only allows easy
        XCTAssertFalse(RecipeFilter.matches(recipe: recipe, profile: p, weekday: 3))
    }

    // MARK: - Combined filters

    func testAllFiltersPassTogether() throws {
        let recipe = try makeRecipe(
            allergenFree: ["nuts", "dairy"],
            dietaryTags: ["vegetarian"],
            difficulty: "easy",
            prepTime: 10,
            cookTime: 15
        )
        let p = profile(
            allergies: [.nuts],
            diets: [.vegetarian],
            difficulties: [.easy],
            maxDuration: .thirty
        )
        XCTAssertTrue(RecipeFilter.matches(recipe: recipe, profile: p))
    }

    func testAllFiltersFailTogether() throws {
        let recipe = try makeRecipe(
            allergenFree: [],
            dietaryTags: [],
            difficulty: "hard",
            prepTime: 40,
            cookTime: 40
        )
        let p = profile(
            allergies: [.nuts],
            diets: [.vegan],
            difficulties: [.easy],
            maxDuration: .thirty
        )
        XCTAssertFalse(RecipeFilter.matches(recipe: recipe, profile: p))
    }
}
