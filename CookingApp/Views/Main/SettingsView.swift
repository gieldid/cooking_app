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

                DisclosureGroup("Per-day Preferences", isExpanded: $showAdvancedSettings) {
                    ForEach(orderedWeekdays, id: \.self) { weekday in
                        NavigationLink {
                            DayPreferencesView(
                                weekday: weekday,
                                dayName: weekdayName(weekday),
                                viewModel: viewModel
                            )
                        } label: {
                            HStack {
                                Text(weekdayName(weekday))
                                Spacer()
                                if viewModel.perDayOverrides[weekday] != nil {
                                    Text("Custom")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            Section("Recipe Preferences") {
                LazyVGrid(columns: difficultyColumns, spacing: 8) {
                    ForEach(Difficulty.allCases) { difficulty in
                        SettingsChip(
                            text: "\(difficulty.icon) \(difficulty.displayName)",
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
                    DatePicker(
                        "Morning Recipe",
                        selection: $viewModel.notificationPreferences.morningRecipeTime,
                        displayedComponents: .hourAndMinute
                    )

                    DatePicker(
                        "Shopping Reminder",
                        selection: $viewModel.notificationPreferences.shoppingListTime,
                        displayedComponents: .hourAndMinute
                    )

                    DatePicker(
                        "Cooking Reminder",
                        selection: $viewModel.notificationPreferences.cookingReminderTime,
                        displayedComponents: .hourAndMinute
                    )
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
                Link("Privacy Policy", destination: URL(string: "https://gieljurriens.nl/inkgredients/")!)
                Link("GDPR", destination: URL(string: "https://gieljurriens.nl/inkgredients/")!)
                Link("Terms of Service", destination: URL(string: "https://gieljurriens.nl/inkgredients/")!)
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
    }
}

private struct DayPreferencesView: View {
    let weekday: Int
    let dayName: String
    @ObservedObject var viewModel: SettingsViewModel

    private let difficultyColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    private var override: DayOverride? { viewModel.perDayOverrides[weekday] }
    private var difficulties: Set<Difficulty> { override?.difficulties ?? viewModel.preferredDifficulties }
    private var duration: MaxDuration { override?.maxDuration ?? viewModel.maxDuration }

    var body: some View {
        Form {
            Section("Difficulty") {
                LazyVGrid(columns: difficultyColumns, spacing: 8) {
                    ForEach(Difficulty.allCases) { difficulty in
                        SettingsChip(
                            text: "\(difficulty.icon) \(difficulty.displayName)",
                            isSelected: difficulties.contains(difficulty)
                        ) {
                            viewModel.togglePerDayDifficulty(weekday: weekday, difficulty: difficulty)
                        }
                    }
                }
                .buttonStyle(.borderless)
                .padding(.vertical, 4)
            }

            Section("Max Cook Time") {
                Picker("Max Cook Time", selection: Binding(
                    get: { duration },
                    set: { viewModel.setPerDayDuration(weekday: weekday, duration: $0) }
                )) {
                    ForEach(MaxDuration.allCases, id: \.self) { d in
                        Text(d.displayName).tag(d)
                    }
                }
            }

            if override != nil {
                Section {
                    Button("Reset to Defaults") {
                        viewModel.clearPerDayOverride(weekday: weekday)
                    }
                    .foregroundStyle(.red)
                } footer: {
                    Text("Removes custom settings for \(dayName) and uses your global preferences.")
                }
            } else {
                Section {
                    EmptyView()
                } footer: {
                    Text("Showing global defaults. Adjust any setting above to create a custom override for \(dayName).")
                }
            }
        }
        .navigationTitle(dayName)
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
    }
}
