import Foundation

enum Allergy: String, Codable, CaseIterable, Identifiable {
    case nuts, dairy, gluten, shellfish, eggs, soy, fish, sesame

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nuts: return "Nuts"
        case .dairy: return "Dairy"
        case .gluten: return "Gluten"
        case .shellfish: return "Shellfish"
        case .eggs: return "Eggs"
        case .soy: return "Soy"
        case .fish: return "Fish"
        case .sesame: return "Sesame"
        }
    }

    var icon: String {
        switch self {
        case .nuts: return "🥜"
        case .dairy: return "🥛"
        case .gluten: return "🌾"
        case .shellfish: return "🦐"
        case .eggs: return "🥚"
        case .soy: return "🫘"
        case .fish: return "🐟"
        case .sesame: return "🌱"
        }
    }
}

enum Diet: String, Codable, CaseIterable, Identifiable {
    case vegetarian, vegan, pescatarian, keto, glutenFree, halal, kosher, dairyFree, lowCarb

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .pescatarian: return "Pescatarian"
        case .keto: return "Keto"
        case .glutenFree: return "Gluten Free"
        case .halal: return "Halal"
        case .kosher: return "Kosher"
        case .dairyFree: return "Dairy Free"
        case .lowCarb: return "Low Carb"
        }
    }

    var icon: String {
        switch self {
        case .vegetarian: return "🥬"
        case .vegan: return "🌿"
        case .pescatarian: return "🐟"
        case .keto: return "🥑"
        case .glutenFree: return "🚫"
        case .halal: return "☪️"
        case .kosher: return "✡️"
        case .dairyFree: return "🥛"
        case .lowCarb: return "📉"
        }
    }
}

struct DietaryProfile: Codable, Equatable {
    var selectedAllergies: Set<Allergy>
    var selectedDiets: Set<Diet>

    static let empty = DietaryProfile(selectedAllergies: [], selectedDiets: [])
}
