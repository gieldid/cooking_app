import SwiftUI

struct NotificationSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Set Reminders")
                    .font(.title)
                    .fontWeight(.bold)

                Text("We'll send you 3 daily notifications to help you cook more.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 24)

            VStack(spacing: 16) {
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
                    time: $viewModel.notificationPreferences.shoppingListTime
                )

                NotificationTimeRow(
                    icon: "flame.fill",
                    title: "Cooking Reminder",
                    subtitle: "Time to start cooking",
                    time: $viewModel.notificationPreferences.cookingReminderTime
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button {
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
                    viewModel.notificationPreferences.isEnabled = false
                    viewModel.nextPage()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

private struct NotificationTimeRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var time: Date

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

            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .accessibilityLabel(title)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
