import SwiftUI

private enum CookingTime: String, CaseIterable, Identifiable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        }
    }

    var timeRange: String {
        switch self {
        case .morning: return "6 – 9 AM"
        case .afternoon: return "12 – 1 PM"
        case .evening: return "5 – 7 PM"
        }
    }

    var iconColor: Color {
        switch self {
        case .morning: return .orange
        case .afternoon: return .yellow
        case .evening: return .indigo
        }
    }

    func apply(to prefs: inout NotificationPreferences) {
        let cal = Calendar.current
        let today = Date()
        func time(_ h: Int, _ m: Int) -> Date {
            cal.date(bySettingHour: h, minute: m, second: 0, of: today) ?? today
        }
        switch self {
        case .morning:
            prefs.morningRecipeTime   = time(6, 0)
            prefs.shoppingListTime    = time(7, 0)
            prefs.cookingReminderTime = time(8, 0)
        case .afternoon:
            prefs.morningRecipeTime   = time(9, 0)
            prefs.shoppingListTime    = time(10, 30)
            prefs.cookingReminderTime = time(12, 0)
        case .evening:
            prefs.morningRecipeTime   = time(8, 0)
            prefs.shoppingListTime    = time(15, 0)
            prefs.cookingReminderTime = time(17, 0)
        }
    }
}

struct NotificationSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var selectedCookingTime: CookingTime? = .evening

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Text("When do you usually cook?")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("We'll set your reminders to match — you can adjust them below.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 24)

                    // Preset chips
                    HStack(spacing: 12) {
                        ForEach(CookingTime.allCases) { preset in
                            CookingTimeChip(
                                preset: preset,
                                isSelected: selectedCookingTime == preset
                            ) {
                                HapticManager.impact(.light)
                                selectedCookingTime = preset
                                preset.apply(to: &viewModel.notificationPreferences)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Fine-tune rows
                    VStack(spacing: 12) {
                        NotificationTimeRow(
                            icon: "fork.knife",
                            title: "Morning Recipe",
                            subtitle: "See today's recipe suggestion",
                            time: $viewModel.notificationPreferences.morningRecipeTime
                        )

                        NotificationTimeRow(
                            icon: "cart.fill",
                            title: "Shopping Reminder",
                            subtitle: "Time to grab ingredients",
                            time: $viewModel.notificationPreferences.shoppingListTime,
                            isEnabled: $viewModel.notificationPreferences.shoppingListEnabled
                        )

                        NotificationTimeRow(
                            icon: "flame.fill",
                            title: "Cooking Reminder",
                            subtitle: "Time to start cooking",
                            time: $viewModel.notificationPreferences.cookingReminderTime
                        )
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 16)
            }

            VStack(spacing: 12) {
                Button {
                    HapticManager.impact(.medium)
                    Task {
                        let granted = await NotificationService.shared.requestPermission()
                        if !granted {
                            viewModel.notificationPreferences.isEnabled = false
                        }
                        viewModel.nextPage()
                    }
                } label: {
                    Text("Enable Notifications & Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button("Skip Notifications") {
                    HapticManager.impact(.light)
                    viewModel.notificationPreferences.isEnabled = false
                    viewModel.nextPage()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 32)
            .background(Color(.systemBackground))
        }
        .onAppear {
            // Apply default preset on first load
            CookingTime.evening.apply(to: &viewModel.notificationPreferences)
        }
    }
}

private struct CookingTimeChip: View {
    let preset: CookingTime
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: preset.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? preset.iconColor : .secondary)
                Text(preset.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(preset.timeRange)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? preset.iconColor.opacity(0.12) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? preset.iconColor : Color.clear, lineWidth: 2)
            )
        }
        .accessibilityLabel("\(preset.rawValue), \(preset.timeRange)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct NotificationTimeRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var time: Date
    var isEnabled: Binding<Bool>? = nil

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.accent)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let enabledBinding = isEnabled {
                Toggle("", isOn: enabledBinding).labelsHidden()
                if enabledBinding.wrappedValue {
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .accessibilityLabel(title)
                }
            } else {
                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .accessibilityLabel(title)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isEnabled?.wrappedValue == false ? 0.5 : 1.0)
    }
}
