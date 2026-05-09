import Foundation

@MainActor
final class AppConfigService: ObservableObject {
    static let shared = AppConfigService()

    @Published var isLifetimeAvailable = false

    private init() {}

    func fetch() async {
        isLifetimeAvailable = (try? await FirestoreService.shared.fetchLifetimeAvailable()) ?? false
    }
}
