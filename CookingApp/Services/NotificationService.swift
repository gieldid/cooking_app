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

        let name = recipeName ?? String(localized: "notification.default_meal")

        scheduleNotification(
            id: .morningRecipe,
            title: String(localized: "notification.morning.title"),
            body: String(format: String(localized: "notification.morning.body"), name),
            time: preferences.morningRecipeTime
        )

        scheduleNotification(
            id: .shoppingList,
            title: String(localized: "notification.shopping.title"),
            body: String(format: String(localized: "notification.shopping.body"), name),
            time: preferences.shoppingListTime
        )

        scheduleNotification(
            id: .cookingReminder,
            title: String(localized: "notification.cooking.title"),
            body: String(format: String(localized: "notification.cooking.body"), name),
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
