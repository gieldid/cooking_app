import SwiftUI

struct SharedRecipeGuestView: View {
    let recipeId: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var revenueCat = RevenueCatService.shared
    @State private var recipe: Recipe? = nil
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var servings = 2
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let recipe {
                    RecipeDetailView(recipe: recipe, servingsMultiplier: $servings)
                        .safeAreaInset(edge: .bottom) {
                            if !revenueCat.isPremium {
                                upsellBanner
                            }
                        }
                } else {
                    errorView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .task { await loadRecipe() }
    }

    private var upsellBanner: some View {
        VStack(spacing: 10) {
            Text("Get a new personalized recipe every day")
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            Button {
                showPaywall = true
            } label: {
                Text("Try Inkgredients Free")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.regularMaterial)
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("Recipe not found")
                .font(.title3)
                .fontWeight(.semibold)
            Text("This recipe may have been removed or the link is invalid.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private func loadRecipe() async {
        isLoading = true
        do {
            recipe = try await FirestoreService.shared.fetchRecipe(id: recipeId)
            if let recipe {
                let defaultServings = UserPreferencesManager.shared.defaultServings
                servings = defaultServings > 0 ? defaultServings : recipe.servings
            }
        } catch {
            loadFailed = true
        }
        isLoading = false
    }
}
