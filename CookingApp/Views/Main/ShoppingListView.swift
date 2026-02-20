import SwiftUI

struct ShoppingListView: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @ObservedObject private var prefs = UserPreferencesManager.shared
    @State private var checkedItems: Set<String> = []

    var body: some View {
        Group {
            if homeViewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading shopping list...")
                        .foregroundStyle(.secondary)
                }
            } else if let recipe = homeViewModel.todayRecipe {
                List {
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.title)
                                    .font(.headline)
                                Text("\(recipe.ingredients.count) ingredients")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(checkedItems.count)/\(recipe.ingredients.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Servings")
                            Spacer()
                            Stepper("\(homeViewModel.servingsMultiplier)", value: $homeViewModel.servingsMultiplier, in: 1...20)
                        }
                    }

                    Section("Ingredients") {
                        ForEach(recipe.localizedIngredients) { ingredient in
                            let disp = displayIngredient(ingredient, recipe: recipe)
                            ShoppingListRow(
                                ingredient: ingredient,
                                amount: disp.amount,
                                unit: disp.unit,
                                isChecked: checkedItems.contains(ingredient.id)
                            ) {
                                if checkedItems.contains(ingredient.id) {
                                    checkedItems.remove(ingredient.id)
                                } else {
                                    checkedItems.insert(ingredient.id)
                                }
                            }
                        }
                    }
                }
            } else if let error = homeViewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text(error)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Try Again") {
                        Task { await homeViewModel.loadTodayRecipe() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "cart")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No recipe selected yet.")
                        .foregroundStyle(.secondary)
                    Text("Check the Today tab for today's recipe.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .navigationTitle("Shopping List")
        .task {
            guard homeViewModel.todayRecipe == nil && !homeViewModel.isLoading else { return }
            await homeViewModel.loadTodayRecipe()
        }
    }

    private func displayIngredient(_ ingredient: Ingredient, recipe: Recipe) -> (amount: String, unit: String) {
        let factor = recipe.servings > 0 ? Double(homeViewModel.servingsMultiplier) / Double(recipe.servings) : 1.0
        return MeasurementConverter.display(
            amount: ingredient.amount,
            unit: ingredient.unit,
            scaleFactor: factor,
            preference: prefs.measurementPreference
        )
    }
}

private struct ShoppingListRow: View {
    let ingredient: Ingredient
    let amount: String
    let unit: String
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? .green : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(ingredient.name)
                        .font(.body)
                        .strikethrough(isChecked)
                        .foregroundStyle(isChecked ? .secondary : .primary)

                    Text("\(amount) \(unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
