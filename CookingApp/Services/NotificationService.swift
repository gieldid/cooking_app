import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private var cachedRecipes: [Recipe] = []

    private let morningPrefix = "com.inkgredients.morning_"

    enum NotificationId: String, CaseIterable {
        case shoppingList = "com.inkgredients.shopping"
        case cookingReminder = "com.inkgredients.cooking"
        case trialReminder = "com.inkgredients.trial_reminder"
    }

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    /// Schedule all notifications. Pass `todayRecipeName` (the actual loaded recipe title)
    /// so the morning notification for today is correct. Future-day notifications use a
    /// generic fallback because the daily pagination cursor advances each day and the
    /// recipe set for any future day cannot be known at scheduling time.
    func scheduleAllNotifications(preferences: NotificationPreferences, recipes: [Recipe] = [], todayRecipeName: String? = nil) {
        if !recipes.isEmpty { cachedRecipes = recipes }
        let effective = cachedRecipes

        guard preferences.isEnabled else {
            cancelAllNotifications()
            return
        }

        scheduleMorningNotifications(preferences: preferences, todayRecipeName: todayRecipeName)

        let fallback = String(localized: "notification.default_meal")
        let todayName = todayRecipeName ?? recipeName(for: Date(), from: effective) ?? fallback

        if preferences.shoppingListEnabled {
            scheduleRepeatingNotification(
                identifier: NotificationId.shoppingList.rawValue,
                title: String(localized: "notification.shopping.title"),
                body: String(format: String(localized: "notification.shopping.body"), todayName),
                time: preferences.shoppingListTime
            )
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [NotificationId.shoppingList.rawValue])
        }

        scheduleRepeatingNotification(
            identifier: NotificationId.cookingReminder.rawValue,
            title: String(localized: "notification.cooking.title"),
            body: String(format: String(localized: "notification.cooking.body"), todayName),
            time: preferences.cookingReminderTime
        )
    }

    private func scheduleMorningNotifications(preferences: NotificationPreferences, todayRecipeName: String?) {
        // Remove the old fixed-id repeating morning notification if it exists
        center.removePendingNotificationRequests(withIdentifiers: ["com.inkgredients.morning"])

        let calendar = Calendar.current
        let timeComps = calendar.dateComponents([.hour, .minute], from: preferences.morningRecipeTime)
        let today = calendar.startOfDay(for: Date())
        let fallback = String(localized: "notification.default_meal")

        for dayOffset in 0..<30 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            // For today use the actual loaded recipe; for future days the pagination cursor
            // will advance so the recipe set is unknown — fall back to a generic name.
            let name = dayOffset == 0 ? (todayRecipeName ?? fallback) : fallback

            var comps = calendar.dateComponents([.year, .month, .day], from: targetDate)
            comps.hour = timeComps.hour
            comps.minute = timeComps.minute

            let content = UNMutableNotificationContent()
            content.title = String(localized: "notification.morning.title")
            content.body = String(format: String(localized: "notification.morning.body"), name)
            content.sound = .default
            content.userInfo = ["notificationType": "com.inkgredients.morning"]

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let id = "\(morningPrefix)\(comps.year ?? 0)\(String(format: "%02d", comps.month ?? 0))\(String(format: "%02d", comps.day ?? 0))"
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    private func recipeName(for date: Date, from recipes: [Recipe]) -> String? {
        guard !recipes.isEmpty else { return nil }
        let dayIndex = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return recipes[dayIndex % recipes.count].title
    }

    private func scheduleRepeatingNotification(identifier: String, title: String, body: String, time: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["notificationType": identifier]

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request)
    }

    func scheduleTrialReminder() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.trial_reminder.title")
        content.body = String(localized: "notification.trial_reminder.body")
        content.sound = .default
        content.userInfo = ["notificationType": NotificationId.trialReminder.rawValue]

        // Fire 24 hours after trial starts (Day 2 of a 3-day trial)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 24 * 3600, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationId.trialReminder.rawValue,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [NotificationId.trialReminder.rawValue])
        center.add(request)
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }
}
