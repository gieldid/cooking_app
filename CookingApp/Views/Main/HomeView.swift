import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                LoadingView()
            } else if let recipe = viewModel.todayRecipe {
                VStack(spacing: 20) {
                    RecipeCard(recipe: recipe, servings: viewModel.servingsMultiplier)

                    HStack(spacing: 16) {
                        Button {
                            viewModel.skipRecipe()
                        } label: {
                            Label("Skip", systemImage: "forward.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .tint(.primary)

                        NavigationLink(destination: RecipeDetailView(recipe: recipe, servingsMultiplier: $viewModel.servingsMultiplier)) {
                            Label("Let's Cook!", systemImage: "flame.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Spacer(minLength: 100)
                    Image("ErrorImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                    Text(error)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Try Again") {
                        Task { await viewModel.loadTodayRecipe() }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle("Today's Recipe")
        .refreshable {
            await viewModel.loadTodayRecipe()
        }
        .task {
            await viewModel.loadTodayRecipe()
        }
    }
}

private struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 80)
            Image("LoadingImage")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .scaleEffect(isAnimating ? 1.08 : 1.0)
                .animation(
                    .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear { isAnimating = true }
            Text("Finding your perfect recipe...")
                .foregroundStyle(.secondary)
        }
    }
}

private struct RecipeCard: View {
    let recipe: Recipe
    let servings: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Image placeholder
            if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        recipePlaceholder
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                recipePlaceholder
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(recipe.localizedDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                HStack(spacing: 16) {
                    Label("\(recipe.prepTime + recipe.cookTime) min", systemImage: "clock")
                    Label("\(servings) servings", systemImage: "person.2")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                // Dietary tags
                if !recipe.dietaryTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recipe.dietaryTags, id: \.self) { tag in
                                Text(tag.capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.15))
                                    .foregroundStyle(.accent)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(.separator), lineWidth: 0.5))
    }

    private var recipePlaceholder: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
        }
    }
}
