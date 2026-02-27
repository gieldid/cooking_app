import SwiftUI

// Shared protocol so both OnboardingViewModel and SettingsViewModel can drive PerDayRow
protocol PerDayPreferencesViewModel: ObservableObject {
    var perDayOverrides: [Int: DayOverride] { get set }
    var globalDifficulties: Set<Difficulty> { get }
    var maxDuration: MaxDuration { get }
    func togglePerDayDifficulty(weekday: Int, difficulty: Difficulty)
    func setPerDayDuration(weekday: Int, duration: MaxDuration)
    func clearPerDayOverride(weekday: Int)
}

struct RecipePreferencesView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    @State private var showPerDay = false

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
        VStack(spacing: 0) {
            // Scrollable content
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Recipe Preferences")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Pick a difficulty and how much time you have to cook.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 24)

                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Difficulty")
                                .font(.headline)
                                .padding(.horizontal, 24)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(Difficulty.allCases) { difficulty in
                                    DifficultyChip(
                                        difficulty: difficulty,
                                        isSelected: viewModel.selectedDifficulties.contains(difficulty)
                                    ) {
                                        viewModel.toggleDifficulty(difficulty)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)

                            Text("Leave blank to show all difficulties.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 24)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Max Cook Time")
                                .font(.headline)
                                .padding(.horizontal, 24)

                            Picker("Max Duration", selection: $viewModel.maxDuration) {
                                ForEach(MaxDuration.allCases, id: \.self) { duration in
                                    Text(duration.displayName).tag(duration)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 24)
                        }

                        DisclosureGroup(isExpanded: $showPerDay) {
                            VStack(spacing: 0) {
                                ForEach(orderedWeekdays, id: \.self) { weekday in
                                    PerDayRow(
                                        weekday: weekday,
                                        dayName: weekdayName(weekday),
                                        columns: columns,
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
                        } label: {
                            Text("Per-day Preferences")
                                .font(.headline)
                        }
                        .padding(.horizontal, 24)
                        .animation(.easeInOut, value: showPerDay)
                    }
                }
                .padding(.bottom, 16)
            }

            // Buttons always pinned at the bottom
            VStack(spacing: 12) {
                Button {
                    viewModel.nextPage()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button("Skip") {
                    viewModel.selectedDifficulties.removeAll()
                    viewModel.maxDuration = .any
                    viewModel.perDayOverrides.removeAll()
                    viewModel.nextPage()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 32)
            .background(Color(.systemBackground))
        }
    }
}

struct PerDayRow<VM: PerDayPreferencesViewModel>: View {
    let weekday: Int
    let dayName: String
    let columns: [GridItem]
    @ObservedObject var viewModel: VM
    @State private var isExpanded = false

    private var override: DayOverride? { viewModel.perDayOverrides[weekday] }
    private var difficulties: Set<Difficulty> { override?.difficulties ?? viewModel.globalDifficulties }
    private var duration: MaxDuration { override?.maxDuration ?? viewModel.maxDuration }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Difficulty.allCases) { difficulty in
                        DifficultyChip(
                            difficulty: difficulty,
                            isSelected: difficulties.contains(difficulty)
                        ) {
                            viewModel.togglePerDayDifficulty(weekday: weekday, difficulty: difficulty)
                        }
                    }
                }

                Picker("Max Cook Time", selection: Binding(
                    get: { duration },
                    set: { viewModel.setPerDayDuration(weekday: weekday, duration: $0) }
                )) {
                    ForEach(MaxDuration.allCases, id: \.self) { d in
                        Text(d.displayName).tag(d)
                    }
                }
                .pickerStyle(.segmented)

                if override != nil {
                    Button("Reset to defaults") {
                        viewModel.clearPerDayOverride(weekday: weekday)
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        } label: {
            HStack {
                Text(dayName)
                    .font(.subheadline)
                Spacer()
                if override != nil {
                    Text("Custom")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .padding(.trailing, 12)
        .animation(.easeInOut, value: isExpanded)
    }
}

struct DifficultyChip: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(difficulty.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
            .foregroundColor(isSelected ? .accentColor : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .accessibilityLabel(difficulty.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "Double tap to deselect" : "Double tap to select")
    }
}
