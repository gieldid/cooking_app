import SwiftUI

struct DietaryPreferencesView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Dietary Preferences")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Select any diets you follow. We'll suggest recipes that fit your lifestyle.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 24)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Diet.allCases) { diet in
                        DietChip(
                            diet: diet,
                            isSelected: viewModel.selectedDiets.contains(diet)
                        ) {
                            viewModel.toggleDiet(diet)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

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
                    viewModel.selectedDiets.removeAll()
                    viewModel.nextPage()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

private struct DietChip: View {
    let diet: Diet
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(diet.icon)
                    .font(.title3)
                    .accessibilityHidden(true)
                Text(diet.displayName)
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
        .accessibilityLabel(diet.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "Double tap to deselect" : "Double tap to select")
    }
}
