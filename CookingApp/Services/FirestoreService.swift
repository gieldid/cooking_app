import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()
    private let recipesCollection = "recipes"
    private let profilesCollection = "dietaryProfiles"
    private let analyticsCollection = "analytics_events"

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
        RecipeFilter.matches(recipe: recipe, profile: profile)
    }

    func fetchRecipe(id: String) async throws -> Recipe? {
        let doc = try await db.collection(recipesCollection).document(id).getDocument()
        return try? doc.data(as: Recipe.self)
    }

    // MARK: - Dietary Profiles (anonymous)

    // MARK: - Analytics events

    /// Fire-and-forget write to the analytics_events collection.
    /// Caller is responsible for including "event" and any event-specific fields.
    func logAnalyticsEvent(_ params: [String: Any]) {
        var data = params
        data["timestamp"] = FieldValue.serverTimestamp()
        db.collection(analyticsCollection).addDocument(data: data)
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
