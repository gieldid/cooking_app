import Foundation

final class UserPreferencesManager: ObservableObject {
    static let shared = UserPreferencesManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let dietaryProfile = "dietaryProfile"
        static let notificationPreferences = "notificationPreferences"
        static let deviceId = "deviceId"
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
