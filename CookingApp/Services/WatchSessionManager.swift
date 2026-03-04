import Foundation
import WatchConnectivity

/// Sends the current recipe to the paired Apple Watch via WatchConnectivity.
final class WatchSessionManager: NSObject {
    static let shared = WatchSessionManager()

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Call this whenever the active recipe changes (load, skip).
    func sendRecipe(_ recipe: Recipe) {
        guard WCSession.isSupported() else { return }

        let payload = WatchRecipePayload(
            title: recipe.title,
            steps: recipe.localizedSteps,
            ingredients: recipe.localizedIngredients.map {
                WatchIngredientPayload(name: $0.name, amount: $0.amount, unit: $0.unit)
            }
        )

        guard let data = try? JSONEncoder().encode(payload) else { return }
        let message = ["recipe": data]

        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil)
        } else {
            // Delivers in the background; watch picks it up on next activation
            try? session.updateApplicationContext(message)
        }
    }
}

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
}

// MARK: - Wire format (mirrors WatchRecipe / WatchIngredient in the watch app)

private struct WatchRecipePayload: Codable {
    let title: String
    let steps: [String]
    let ingredients: [WatchIngredientPayload]
}

private struct WatchIngredientPayload: Codable {
    let name: String
    let amount: String
    let unit: String
}
