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
        let profileHash = profile.paginationHash

        if let cached = loadRecipeCache(), cached.date == todayString, cached.profileHash == profileHash {
            return cached.recipes
        }

        let cursor = paginationCursor(for: profileHash)
        let (recipes, lastDocId) = try await fetchPage(profile: profile, startAfterDocId: cursor)

        if recipes.isEmpty && cursor != nil {
            resetPagination(profileHash: profileHash)
            return try await fetchFilteredRecipes(profile: profile)
        }

        saveNextCursor(lastDocId, profileHash: profileHash)
        saveRecipeCache(RecipeCache(recipes: recipes, date: todayString, profileHash: profileHash))
        return recipes
    }

    /// Fetches the page immediately following the current one. Called when the user
    /// skips through all recipes in the current batch.
    func fetchNextPage(profile: DietaryProfile) async throws -> [Recipe] {
        let profileHash = profile.paginationHash
        let state = loadState()
        let nextCursor = state?.nextPageCursor

        let (recipes, lastDocId) = try await fetchPage(profile: profile, startAfterDocId: nextCursor)

        if recipes.isEmpty {
            // Reached end of collection — wrap around to the beginning
            resetPagination(profileHash: profileHash)
            let (wrapped, wrappedLast) = try await fetchPage(profile: profile, startAfterDocId: nil)
            saveState(PaginationState(
                pageStartCursor: nil, nextPageCursor: wrappedLast,
                date: todayString, profileHash: profileHash
            ))
            return wrapped
        }

        saveState(PaginationState(
            pageStartCursor: nextCursor, nextPageCursor: lastDocId,
            date: todayString, profileHash: profileHash
        ))
        return recipes
    }

    // How many client-side matched recipes to collect per page.
    private let pageSize = 30
    // How many documents to fetch from Firestore per round-trip.
    private let batchSize = 50
    // Maximum round-trips per page to cap worst-case reads.
    private let maxBatches = 5

    private func fetchPage(profile: DietaryProfile, startAfterDocId: String?) async throws -> (recipes: [Recipe], lastDocId: String?) {
        var results: [Recipe] = []
        var cursorDocId = startAfterDocId
        var batches = 0

        while results.count < pageSize && batches < maxBatches {
            var query = baseQuery(for: profile)

            if let docId = cursorDocId {
                let cursorDoc = try await db.collection(recipesCollection).document(docId).getDocument()
                if cursorDoc.exists {
                    query = query.start(afterDocument: cursorDoc)
                }
            }

            let snapshot = try await query.limit(to: batchSize).getDocuments()
            batches += 1

            let filtered = snapshot.documents.compactMap { doc -> Recipe? in
                guard var recipe = try? doc.data(as: Recipe.self) else { return nil }
                recipe.id = doc.documentID
                return recipe
            }.filter { matchesProfile(recipe: $0, profile: profile) }

            results.append(contentsOf: filtered)
            cursorDocId = snapshot.documents.last?.documentID

            // Fewer docs than requested means we've reached the end of the collection
            if snapshot.documents.count < batchSize { break }
        }

        return (Array(results.prefix(pageSize)), cursorDocId)
    }

    /// Builds the base Firestore query with all applicable server-side filters.
    /// Firestore limits: one array-contains per query; range filters on one field only.
    ///   - dietaryTags: uses the array-contains slot
    ///   - prepTime / calories: uses the range slot (prepTime takes priority)
    ///   - allergenFree + remaining diets: client-side only
    /// Composite indexes required in Firebase Console for the array-contains + range combinations.
    private func baseQuery(for profile: DietaryProfile) -> Query {
        var query: Query = db.collection(recipesCollection)

        if let primaryDiet = profile.selectedDiets.first {
            query = query.whereField("dietaryTags", arrayContains: primaryDiet.rawValue)
        }

        if let maxMinutes = profile.maxDuration.minutes {
            query = query.whereField("prepTime", isLessThanOrEqualTo: maxMinutes)
            query = query.order(by: "prepTime")
        } else if let calLimit = profile.maxCalories.limit {
            query = query.whereField("nutrition.calories", isLessThanOrEqualTo: calLimit)
            query = query.order(by: "nutrition.calories")
        }

        return query.order(by: FieldPath.documentID())
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

    // MARK: - Pagination state

    private struct PaginationState: Codable {
        var pageStartCursor: String?
        var nextPageCursor: String?
        var date: String
        var profileHash: String
    }

    private let paginationDefaultsKey = "recipePaginationState"

    private var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func loadState() -> PaginationState? {
        guard let data = UserDefaults.standard.data(forKey: paginationDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(PaginationState.self, from: data)
    }

    private func saveState(_ state: PaginationState) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: paginationDefaultsKey)
        }
    }

    private func paginationCursor(for profileHash: String) -> String? {
        let today = todayString
        var state = loadState() ?? PaginationState(
            pageStartCursor: nil, nextPageCursor: nil, date: "", profileHash: ""
        )

        if state.profileHash != profileHash {
            state = PaginationState(pageStartCursor: nil, nextPageCursor: nil, date: today, profileHash: profileHash)
            saveState(state)
            return nil
        }

        if state.date == today {
            return state.pageStartCursor
        }

        state.pageStartCursor = state.nextPageCursor
        state.date = today
        saveState(state)
        return state.pageStartCursor
    }

    private func saveNextCursor(_ docId: String?, profileHash: String) {
        var state = loadState() ?? PaginationState(
            pageStartCursor: nil, nextPageCursor: nil, date: todayString, profileHash: profileHash
        )
        state.nextPageCursor = docId
        saveState(state)
    }

    private func resetPagination(profileHash: String) {
        saveState(PaginationState(
            pageStartCursor: nil, nextPageCursor: nil, date: todayString, profileHash: profileHash
        ))
    }

    // MARK: - Recipe cache

    private struct RecipeCache: Codable {
        var recipes: [Recipe]
        var date: String
        var profileHash: String
    }

    private static var recipeCacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("recipesCache.json")
    }

    private func loadRecipeCache() -> RecipeCache? {
        guard let data = try? Data(contentsOf: Self.recipeCacheURL) else { return nil }
        return try? JSONDecoder().decode(RecipeCache.self, from: data)
    }

    private func saveRecipeCache(_ cache: RecipeCache) {
        if let data = try? JSONEncoder().encode(cache) {
            try? data.write(to: Self.recipeCacheURL, options: .atomic)
        }
    }

    // MARK: - App Config

    func fetchLifetimeAvailable() async throws -> Bool {
        let doc = try await db.collection("config").document("app").getDocument()
        return doc.data()?["lifetimeAvailable"] as? Bool ?? false
    }

    // MARK: - Analytics events

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
