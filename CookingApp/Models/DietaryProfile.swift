import Foundation

enum Allergy: String, Codable, CaseIterable, Identifiable {
    case nuts, dairy, gluten, shellfish, eggs, soy, fish, sesame

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nuts: return String(localized: "allergy.nuts")
        case .dairy: return String(localized: "allergy.dairy")
        case .gluten: return String(localized: "allergy.gluten")
        case .shellfish: return String(localized: "allergy.shellfish")
        case .eggs: return String(localized: "allergy.eggs")
        case .soy: return String(localized: "allergy.soy")
        case .fish: return String(localized: "allergy.fish")
        case .sesame: return String(localized: "allergy.sesame")
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
    case vegetarian, vegan, pescatarian, keto, glutenFree, halal, kosher, dairyFree, lowCarb, highProtein

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vegetarian: return String(localized: "diet.vegetarian")
        case .vegan: return String(localized: "diet.vegan")
        case .pescatarian: return String(localized: "diet.pescatarian")
        case .keto: return String(localized: "diet.keto")
        case .glutenFree: return String(localized: "diet.glutenFree")
        case .halal: return String(localized: "diet.halal")
        case .kosher: return String(localized: "diet.kosher")
        case .dairyFree: return String(localized: "diet.dairyFree")
        case .lowCarb: return String(localized: "diet.lowCarb")
        case .highProtein: return String(localized: "diet.highProtein")
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
        case .highProtein: return "💪"
        }
    }
}

enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case easy, medium, hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: return String(localized: "difficulty.easy")
        case .medium: return String(localized: "difficulty.medium")
        case .hard: return String(localized: "difficulty.hard")
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
        case .any:    return String(localized: "duration.any")
        case .thirty: return String(localized: "duration.thirty")
        case .sixty:  return String(localized: "duration.sixty")
        case .ninety: return String(localized: "duration.ninety")
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

// Per-weekday overrides for difficulty and duration.
// weekday key matches Calendar.current.component(.weekday, from:): 1=Sunday, 2=Monday … 7=Saturday.
struct DayOverride: Codable, Equatable {
    var difficulties: Set<Difficulty>
    var maxDuration: MaxDuration
}

struct DietaryProfile: Codable, Equatable {
    var selectedAllergies: Set<Allergy>
    var selectedDiets: Set<Diet>
    var preferredDifficulties: Set<Difficulty>
    var maxDuration: MaxDuration
    var perDayOverrides: [Int: DayOverride]

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
        maxDuration: MaxDuration = .any,
        perDayOverrides: [Int: DayOverride] = [:]
    ) {
        self.selectedAllergies = selectedAllergies
        self.selectedDiets = selectedDiets
        self.preferredDifficulties = preferredDifficulties
        self.maxDuration = maxDuration
        self.perDayOverrides = perDayOverrides
    }

    // Custom decoder so existing stored data (without the new keys) still loads cleanly.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedAllergies = try container.decode(Set<Allergy>.self, forKey: .selectedAllergies)
        selectedDiets = try container.decode(Set<Diet>.self, forKey: .selectedDiets)
        preferredDifficulties = try container.decodeIfPresent(Set<Difficulty>.self, forKey: .preferredDifficulties) ?? []
        maxDuration = try container.decodeIfPresent(MaxDuration.self, forKey: .maxDuration) ?? .any
        perDayOverrides = try container.decodeIfPresent([Int: DayOverride].self, forKey: .perDayOverrides) ?? [:]
    }
}
