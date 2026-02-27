import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var prefs = UserPreferencesManager.shared
    @ObservedObject private var rcService = RevenueCatService.shared
    @State private var showResetAlert = false
    @State private var showAdvancedSettings = false

    let allergyColumns = [GridItem(.flexible()), GridItem(.flexible())]
    let dietColumns = [GridItem(.flexible()), GridItem(.flexible())]
    let difficultyColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    // Calendar weekday order: Mon–Sun (2–7, then 1)
    private let orderedWeekdays = [2, 3, 4, 5, 6, 7, 1]

    private func weekdayName(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return ""
        }
    }

    var body: some View {
        Form {
            Section("Allergies") {
                LazyVGrid(columns: allergyColumns, spacing: 8) {
                    ForEach(Allergy.allCases) { allergy in
                        SettingsChip(
                            text: "\(allergy.icon) \(allergy.displayName)",
                            isSelected: viewModel.selectedAllergies.contains(allergy)
                        ) {
                            viewModel.toggleAllergy(allergy)
                        }
                    }
                }
                .buttonStyle(.borderless)
                .padding(.vertical, 4)
            }

            Section("Dietary Preferences") {
                LazyVGrid(columns: dietColumns, spacing: 8) {
                    ForEach(Diet.allCases) { diet in
                        SettingsChip(
                            text: "\(diet.icon) \(diet.displayName)",
                            isSelected: viewModel.selectedDiets.contains(diet)
                        ) {
                            viewModel.toggleDiet(diet)
                        }
                    }
                }
                .buttonStyle(.borderless)
                .padding(.vertical, 4)

            }

            Section("Recipe Preferences") {
                LazyVGrid(columns: difficultyColumns, spacing: 8) {
                    ForEach(Difficulty.allCases) { difficulty in
                        SettingsChip(
                            text: difficulty.displayName,
                            isSelected: viewModel.preferredDifficulties.contains(difficulty)
                        ) {
                            viewModel.toggleDifficulty(difficulty)
                        }
                    }
                }
                .buttonStyle(.borderless)
                .padding(.vertical, 4)

                Picker("Max Cook Time", selection: $viewModel.maxDuration) {
                    ForEach(MaxDuration.allCases, id: \.self) { d in
                        Text(d.displayName).tag(d)
                    }
                }

                let stepperLabel = prefs.defaultServings == 0
                    ? "Default Servings: Recipe Default"
                    : "Default Servings: \(prefs.defaultServings)"
                Stepper(stepperLabel, value: $prefs.defaultServings, in: 0...20)

                DisclosureGroup("Per-day Preferences", isExpanded: $showAdvancedSettings) {
                    VStack(spacing: 0) {
                        ForEach(orderedWeekdays, id: \.self) { weekday in
                            PerDayRow(
                                weekday: weekday,
                                dayName: weekdayName(weekday),
                                columns: difficultyColumns,
                                viewModel: viewModel
                            )
                            if weekday != orderedWeekdays.last {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 8)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                }
                .animation(.easeInOut, value: showAdvancedSettings)
            }

            Section("Units") {
                Picker("Measurement System", selection: $prefs.measurementPreference) {
                    ForEach(MeasurementPreference.allCases, id: \.self) { pref in
                        Text(pref.displayName).tag(pref)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $viewModel.notificationPreferences.isEnabled)

                if viewModel.notificationPreferences.isEnabled {
                    NotificationTimeRow(
                        icon: "fork.knife",
                        title: "Morning Recipe",
                        subtitle: "See today's recipe suggestion",
                        time: $viewModel.notificationPreferences.morningRecipeTime
                    )
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)

                    NotificationTimeRow(
                        icon: "cart.fill",
                        title: "Shopping Reminder",
                        subtitle: "Time to grab ingredients",
                        time: $viewModel.notificationPreferences.shoppingListTime,
                        isEnabled: $viewModel.notificationPreferences.shoppingListEnabled
                    )
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)

                    NotificationTimeRow(
                        icon: "flame.fill",
                        title: "Cooking Reminder",
                        subtitle: "Time to start cooking",
                        time: $viewModel.notificationPreferences.cookingReminderTime
                    )
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }

            Section("Subscription") {
                Label(
                    rcService.isPremium ? "Premium Active" : "No Active Subscription",
                    systemImage: rcService.isPremium ? "checkmark.seal.fill" : "xmark.seal"
                )
                .foregroundStyle(rcService.isPremium ? .green : .secondary)

                Button("Manage Subscription") {
                    if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Restore Purchases") {
                    Task { try? await rcService.restorePurchases() }
                }
                .foregroundStyle(.secondary)
            }

Section("Legal") {
                Link("Privacy Policy", destination: URL(string: "https://gieljurriens.nl/inkgredients/#privacy")!)
                Link("GDPR", destination: URL(string: "https://gieljurriens.nl/inkgredients/#gdpr")!)
                Link("Terms of Service", destination: URL(string: "https://gieljurriens.nl/inkgredients/#terms")!)
            }

            Section {
                Button("Reset & Show Onboarding") {
                    showResetAlert = true
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Settings")
        .alert("Reset App?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                viewModel.resetOnboarding()
            }
        } message: {
            Text("This will clear all your preferences and show the onboarding flow again.")
        }
        .trackScreenTime("settings")
    }
}


private struct SettingsChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                .foregroundColor(isSelected ? .accentColor : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "Double tap to deselect" : "Double tap to select")
    }
}
