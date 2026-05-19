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

    func fetchFilteredRecipes(profile: DietaryProfile) async throws -> [Recipe] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        var recipes = try await fetchRecipes(from: today, to: tomorrow, profile: profile)

        // Backend hasn't run yet today — fall back to yesterday's batch
        if recipes.isEmpty {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            recipes = try await fetchRecipes(from: yesterday, to: today, profile: profile)
        }

        return recipes
    }

    private func fetchRecipes(from start: Date, to end: Date, profile: DietaryProfile) async throws -> [Recipe] {
        let snapshot = try await db.collection(recipesCollection)
            .whereField("createdAt", isGreaterThanOrEqualTo: start)
            .whereField("createdAt", isLessThan: end)
            .getDocuments()

        let recipes = snapshot.documents.compactMap { doc -> Recipe? in
            guard var recipe = try? doc.data(as: Recipe.self) else { return nil }
            recipe.id = doc.documentID
            return recipe
        }

        return recipes.filter { matchesProfile(recipe: $0, profile: profile) }
    }

    private func matchesProfile(recipe: Recipe, profile: DietaryProfile) -> Bool {
        RecipeFilter.matches(recipe: recipe, profile: profile)
    }

    func fetchRecipe(id: String) async throws -> Recipe? {
        let doc = try await db.collection(recipesCollection).document(id).getDocument()
        guard var recipe = try? doc.data(as: Recipe.self) else { return nil }
        recipe.id = doc.documentID
        return recipe
    }

    // MARK: - Dietary Profiles (anonymous)

    // MARK: - App Config

    func fetchLifetimeAvailable() async throws -> Bool {
        let doc = try await db.collection("config").document("app").getDocument()
        return doc.data()?["lifetimeAvailable"] as? Bool ?? false
    }

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
