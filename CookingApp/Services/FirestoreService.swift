import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()
    private let recipesCollection = "recipes"
    private let profilesCollection = "dietaryProfiles"

    private init() {}

    // MARK: - Recipes

    func fetchRecipes() async throws -> [Recipe] {
        let snapshot = try await db.collection(recipesCollection).getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Recipe.self)
        }
    }

    func fetchFilteredRecipes(profile: DietaryProfile) async throws -> [Recipe] {
        let allRecipes = try await fetchRecipes()
        return allRecipes.filter { recipe in
            matchesProfile(recipe: recipe, profile: profile)
        }
    }

    private func matchesProfile(recipe: Recipe, profile: DietaryProfile) -> Bool {
        // Allergens: recipe must be free of all user allergies
        for allergy in profile.selectedAllergies {
            if !recipe.allergenFree.contains(allergy.rawValue) {
                return false
            }
        }

        // Dietary tags: recipe must match at least one selected diet
        if !profile.selectedDiets.isEmpty {
            let recipeTags = Set(recipe.dietaryTags)
            let userDiets = Set(profile.selectedDiets.map { $0.rawValue })
            if recipeTags.isDisjoint(with: userDiets) {
                return false
            }
        }

        // Difficulty: recipe must match one of the preferred difficulties (if any selected)
        if !profile.preferredDifficulties.isEmpty {
            guard let diff = recipe.difficulty,
                  profile.preferredDifficulties.map({ $0.rawValue }).contains(diff) else {
                return false
            }
        }

        // Duration: recipe total time must be within the limit
        if let maxMinutes = profile.maxDuration.minutes, recipe.totalTime > maxMinutes {
            return false
        }

        return true
    }

    // MARK: - Dietary Profiles (anonymous)

    func pushDietaryProfile(_ profile: DietaryProfile, deviceId: String) async throws {
        let data: [String: Any] = [
            "deviceId": deviceId,
            "allergies": profile.selectedAllergies.map { $0.rawValue },
            "diets": profile.selectedDiets.map { $0.rawValue },
            "createdAt": FieldValue.serverTimestamp()
        ]

        try await db.collection(profilesCollection).document(deviceId).setData(data)
    }
}
