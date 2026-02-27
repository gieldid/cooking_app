import Foundation

struct NotificationPreferences: Codable, Equatable {
    var morningRecipeTime: Date
    var shoppingListTime: Date
    var cookingReminderTime: Date
    var isEnabled: Bool
    var shoppingListEnabled: Bool

    static let `default`: NotificationPreferences = {
        let calendar = Calendar.current
        let today = Date()
        let morning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today)
            ?? today.addingTimeInterval(8 * 3600)
        let shopping = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)
            ?? today.addingTimeInterval(10 * 3600)
        let cooking = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: today)
            ?? today.addingTimeInterval(17 * 3600)
        return NotificationPreferences(
            morningRecipeTime: morning,
            shoppingListTime: shopping,
            cookingReminderTime: cooking,
            isEnabled: true,
            shoppingListEnabled: true
        )
    }()
}
