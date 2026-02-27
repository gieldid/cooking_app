import SwiftUI

struct FavouritesView: View {
    @ObservedObject private var prefs = UserPreferencesManager.shared

    var body: some View {
        Group {
            if prefs.favouriteRecipes.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(prefs.favouriteRecipes) { recipe in
                        NavigationLink {
                            RecipeServingsWrapper(recipe: recipe)
                        } label: {
                            FavouriteRow(recipe: recipe)
                        }
                    }
                    .onDelete { indexSet in
                        prefs.favouriteRecipes.remove(atOffsets: indexSet)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(String(localized: "Favourites"))
        .trackScreenTime("favourites")
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(String(localized: "No favourites yet"))
                .font(.title3)
                .fontWeight(.semibold)
            Text(String(localized: "Tap the heart on any recipe to save it here."))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

private struct RecipeServingsWrapper: View {
    let recipe: Recipe
    @State private var servings: Int

    init(recipe: Recipe) {
        self.recipe = recipe
        let defaultServings = UserPreferencesManager.shared.defaultServings
        self._servings = State(initialValue: defaultServings > 0 ? defaultServings : recipe.servings)
    }

    var body: some View {
        RecipeDetailView(recipe: recipe, servingsMultiplier: $servings)
    }
}

private struct FavouriteRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Color(.systemGray5)
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.secondary)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(2)
                HStack(spacing: 10) {
                    Label("\(recipe.totalTime) min", systemImage: "clock")
                    if let difficulty = recipe.difficulty {
                        Label(difficulty.capitalized, systemImage: "chart.bar")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
