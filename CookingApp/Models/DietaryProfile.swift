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

enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case easy, medium, hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var icon: String {
        switch self {
        case .easy: return "🟢"
        case .medium: return "🟡"
        case .hard: return "🔴"
        }
    }
}

enum MaxDuration: String, Codable, CaseIterable {
    case any, thirty, sixty, ninety

    var displayName: String {
        switch self {
        case .any:    return "Any"
        case .thirty: return "≤ 30 min"
        case .sixty:  return "≤ 60 min"
        case .ninety: return "≤ 90 min"
        }
    }

    var minutes: Int? {
        switch self {
        case .any:    return nil
        case .thirty: return 30
        case .sixty:  return 60
        case .ninety: return 90
        }
    }
}

struct DietaryProfile: Codable, Equatable {
    var selectedAllergies: Set<Allergy>
    var selectedDiets: Set<Diet>
    var preferredDifficulties: Set<Difficulty>
    var maxDuration: MaxDuration

    static let empty = DietaryProfile(
        selectedAllergies: [],
        selectedDiets: [],
        preferredDifficulties: [],
        maxDuration: .any
    )

    init(
        selectedAllergies: Set<Allergy>,
        selectedDiets: Set<Diet>,
        preferredDifficulties: Set<Difficulty> = [],
        maxDuration: MaxDuration = .any
    ) {
        self.selectedAllergies = selectedAllergies
        self.selectedDiets = selectedDiets
        self.preferredDifficulties = preferredDifficulties
        self.maxDuration = maxDuration
    }

    // Custom decoder so existing stored data (without the new keys) still loads cleanly.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedAllergies = try container.decode(Set<Allergy>.self, forKey: .selectedAllergies)
        selectedDiets = try container.decode(Set<Diet>.self, forKey: .selectedDiets)
        preferredDifficulties = try container.decodeIfPresent(Set<Difficulty>.self, forKey: .preferredDifficulties) ?? []
        maxDuration = try container.decodeIfPresent(MaxDuration.self, forKey: .maxDuration) ?? .any
    }
}
