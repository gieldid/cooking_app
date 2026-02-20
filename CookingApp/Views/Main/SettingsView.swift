import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var prefs = UserPreferencesManager.shared
    @State private var showResetAlert = false

    let allergyColumns = [GridItem(.flexible()), GridItem(.flexible())]
    let dietColumns = [GridItem(.flexible()), GridItem(.flexible())]

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
