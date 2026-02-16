import SwiftUI

struct AllergiesView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Any Allergies?")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Select any food allergies you have. We'll filter recipes to keep you safe.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 24)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Allergy.allCases) { allergy in
                        AllergyChip(
                            allergy: allergy,
                            isSelected: viewModel.selectedAllergies.contains(allergy)
                        ) {
                            viewModel.toggleAllergy(allergy)
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
                    viewModel.selectedAllergies.removeAll()
                    viewModel.nextPage()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

private struct AllergyChip: View {
    let allergy: Allergy
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(allergy.icon)
                    .font(.title3)
                Text(allergy.displayName)
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
