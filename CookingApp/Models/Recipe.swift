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
    let descriptionNl: String?
    let descriptionFr: String?
    let descriptionDe: String?
    let descriptionIt: String?
    let ingredients: [Ingredient]
    let ingredientNamesNl: [String]?
    let ingredientNamesFr: [String]?
    let ingredientNamesDe: [String]?
    let ingredientNamesIt: [String]?
    let steps: [String]
    let stepsNl: [String]?
    let stepsFr: [String]?
    let stepsDe: [String]?
    let stepsIt: [String]?
    let dietaryTags: [String]
    let allergenFree: [String]
    let prepTime: Int
    let cookTime: Int
    let imageURL: String?
    let servings: Int
    let difficulty: String?

    var totalTime: Int { prepTime + cookTime }

    var localizedDescription: String {
        switch Locale.current.languageCode {
        case "nl": return descriptionNl ?? description
        case "fr": return descriptionFr ?? description
        case "de": return descriptionDe ?? description
        case "it": return descriptionIt ?? description
        default:   return description
        }
    }

    var localizedSteps: [String] {
        switch Locale.current.languageCode {
        case "nl": return stepsNl ?? steps
        case "fr": return stepsFr ?? steps
        case "de": return stepsDe ?? steps
        case "it": return stepsIt ?? steps
        default:   return steps
        }
    }

    var localizedIngredients: [Ingredient] {
        let names: [String]?
        switch Locale.current.languageCode {
        case "nl": names = ingredientNamesNl
        case "fr": names = ingredientNamesFr
        case "de": names = ingredientNamesDe
        case "it": names = ingredientNamesIt
        default:   names = nil
        }
        guard let names, names.count == ingredients.count else { return ingredients }
        return zip(ingredients, names).map { Ingredient(name: $1, amount: $0.amount, unit: $0.unit) }
    }
}
