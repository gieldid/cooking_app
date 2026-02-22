import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @Binding var servingsMultiplier: Int
    @State private var completedSteps: Set<Int> = []
    @ObservedObject private var prefs = UserPreferencesManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header image
                if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            imagePlaceholder
                        }
                    }
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    imagePlaceholder
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                VStack(alignment: .leading, spacing: 20) {
                    // Title and info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(recipe.localizedDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 20) {
                            InfoBadge(icon: "clock", text: "\(recipe.prepTime)m prep")
                            InfoBadge(icon: "flame", text: "\(recipe.cookTime)m cook")
                            InfoBadge(icon: "person.2", text: "\(servingsMultiplier) servings")
                        }
                        .padding(.top, 4)
                    }

                    Divider()

                    // Servings adjuster
                    HStack {
                        Text("Servings")
                            .font(.headline)
                        Spacer()
                        Stepper(String(servingsMultiplier), value: $servingsMultiplier, in: 1...20)
                    }

                    Divider()

                    // Ingredients
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.title2)
                            .fontWeight(.bold)

                        ForEach(recipe.localizedIngredients) { ingredient in
                            let disp = displayIngredient(ingredient)
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 6, height: 6)

                                Text(disp.amount)
                                    .fontWeight(.semibold)
                                    .frame(width: 60, alignment: .leading)

                                Text(verbatim: "\(disp.unit) \(ingredient.name)")
                            }
                            .font(.body)
                        }
                    }

                    Divider()

                    // Steps
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Instructions")
                            .font(.title2)
                            .fontWeight(.bold)

                        ForEach(Array(recipe.localizedSteps.enumerated()), id: \.offset) { index, step in
                            StepRow(
                                stepNumber: index + 1,
                                text: step,
                                isCompleted: completedSteps.contains(index)
                            ) {
                                if completedSteps.contains(index) {
                                    completedSteps.remove(index)
                                } else {
                                    completedSteps.insert(index)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func displayIngredient(_ ingredient: Ingredient) -> (amount: String, unit: String) {
        let factor = recipe.servings > 0 ? Double(servingsMultiplier) / Double(recipe.servings) : 1.0
        return MeasurementConverter.display(
            amount: ingredient.amount,
            unit: ingredient.unit,
            scaleFactor: factor,
            preference: prefs.measurementPreference
        )
    }

    private var imagePlaceholder: some View {
        Image("LoadingImage")
            .resizable()
            .scaledToFill()
    }
}

private struct InfoBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

private struct StepRow: View {
    let stepNumber: Int
    let text: String
    let isCompleted: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : Color.accentColor)
                        .frame(width: 28, height: 28)
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Text("\(stepNumber)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }

                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
            }
        }
        .buttonStyle(.plain)
    }
}
