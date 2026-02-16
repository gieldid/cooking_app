import SwiftUI

struct ShoppingListView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var checkedItems: Set<String> = []

    var body: some View {
        NavigationStack {
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
                        }

                        Section("Ingredients") {
                            ForEach(recipe.ingredients) { ingredient in
                                ShoppingListRow(
                                    ingredient: ingredient,
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

                        if !checkedItems.isEmpty {
                            Section {
                                Button("Uncheck All") {
                                    checkedItems.removeAll()
                                }
                                .foregroundStyle(.red)
                            }
                        }
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
                await homeViewModel.loadTodayRecipe()
            }
        }
    }
}

private struct ShoppingListRow: View {
    let ingredient: Ingredient
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

                    Text("\(ingredient.amount) \(ingredient.unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
