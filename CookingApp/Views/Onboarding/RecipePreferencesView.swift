import SwiftUI

struct RecipePreferencesView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
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
            }

            Spacer()

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
                    viewModel.nextPage()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

private struct DifficultyChip: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(difficulty.icon)
                    .font(.title2)
                Text(difficulty.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
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
    }
}
