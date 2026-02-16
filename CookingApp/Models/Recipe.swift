import Foundation
import FirebaseFirestore

struct Ingredient: Codable, Identifiable, Hashable {
    var id: String { name + amount + unit }
    let name: String
    let amount: String
    let unit: String
}

struct Recipe: Codable, Identifiable {
    @DocumentID var id: String?
    let title: String
    let description: String
    let ingredients: [Ingredient]
    let steps: [String]
    let dietaryTags: [String]
    let allergenFree: [String]
    let prepTime: Int
    let cookTime: Int
    let imageURL: String?
    let servings: Int

    var totalTime: Int { prepTime + cookTime }
}
