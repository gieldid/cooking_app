import Foundation

enum MeasurementPreference: String, Codable, CaseIterable {
    case system, metric, imperial

    var displayName: String {
        switch self {
        case .system: return String(localized: "measurement.system")
        case .metric: return String(localized: "measurement.metric")
        case .imperial: return String(localized: "measurement.imperial")
        }
    }

    var usesMetric: Bool {
        switch self {
        case .metric: return true
        case .imperial: return false
        case .system: return Locale.current.measurementSystem != .us
        }
    }
}

final class UserPreferencesManager: ObservableObject {
    static let shared = UserPreferencesManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let dietaryProfile = "dietaryProfile"
        static let notificationPreferences = "notificationPreferences"
        static let deviceId = "deviceId"
        static let measurementPreference = "measurementPreference"
        static let defaultServings = "defaultServings"
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    @Published var dietaryProfile: DietaryProfile {
        didSet { saveCodable(dietaryProfile, forKey: Keys.dietaryProfile) }
    }

    @Published var notificationPreferences: NotificationPreferences {
        didSet { saveCodable(notificationPreferences, forKey: Keys.notificationPreferences) }
    }

    @Published var measurementPreference: MeasurementPreference {
        didSet { saveCodable(measurementPreference, forKey: Keys.measurementPreference) }
    }

    /// 0 means "use each recipe's own serving count".
    @Published var defaultServings: Int {
        didSet { defaults.set(defaultServings, forKey: Keys.defaultServings) }
    }

    var deviceId: String {
        if let existing = defaults.string(forKey: Keys.deviceId) {
            return existing
        }
        let newId = UUID().uuidString
        defaults.set(newId, forKey: Keys.deviceId)
        return newId
    }

    private init() {
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        self.dietaryProfile = Self.loadCodable(forKey: Keys.dietaryProfile) ?? .empty
        self.notificationPreferences = Self.loadCodable(forKey: Keys.notificationPreferences) ?? .default
        self.measurementPreference = Self.loadCodable(forKey: Keys.measurementPreference) ?? .system
        self.defaultServings = defaults.integer(forKey: Keys.defaultServings) // 0 if never set
    }

    private func saveCodable<T: Codable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func loadCodable<T: Codable>(forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        dietaryProfile = .empty
        notificationPreferences = .default
    }
}
