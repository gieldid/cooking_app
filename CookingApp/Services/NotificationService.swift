import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    enum NotificationId: String, CaseIterable {
        case morningRecipe = "com.cookingapp.morning"
        case shoppingList = "com.cookingapp.shopping"
        case cookingReminder = "com.cookingapp.cooking"
    }

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleAllNotifications(preferences: NotificationPreferences, recipeName: String?) {
        guard preferences.isEnabled else {
            cancelAllNotifications()
            return
        }

        let name = recipeName ?? "a delicious meal"

        scheduleNotification(
            id: .morningRecipe,
            title: "Today's Recipe!",
            body: "Today's recipe: \(name)! Tap to see if you'd like it.",
            time: preferences.morningRecipeTime
        )

        scheduleNotification(
            id: .shoppingList,
            title: "Shopping List Ready",
            body: "Don't forget to grab ingredients for \(name)! Tap for your shopping list.",
            time: preferences.shoppingListTime
        )

        scheduleNotification(
            id: .cookingReminder,
            title: "Time to Cook!",
            body: "Time to start cooking \(name)! Let's go!",
            time: preferences.cookingReminderTime
        )
    }

    private func scheduleNotification(id: NotificationId, title: String, body: String, time: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["notificationType": id.rawValue]

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: id.rawValue, content: content, trigger: trigger)

        center.removePendingNotificationRequests(withIdentifiers: [id.rawValue])
        center.add(request)
    }

    func cancelAllNotifications() {
        let ids = NotificationId.allCases.map { $0.rawValue }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
