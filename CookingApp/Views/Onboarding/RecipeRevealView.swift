import SwiftUI

struct RecipeRevealView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoadingPreview {
                loadingState
            } else if let recipe = viewModel.previewRecipe {
                recipeCard(recipe)
            } else {
                fallbackCard
            }
        }
        .task {
            await viewModel.fetchRecipePreview()
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Finding your perfect recipe…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            ctaButton
        }
    }

    // MARK: - Recipe card

    private func recipeCard(_ recipe: Recipe) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero image
                    Group {
                        if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fill)
                                default:
                                    Image("LoadingImage").resizable().scaledToFill()
                                }
                            }
                        } else {
                            Image("LoadingImage").resizable().scaledToFill()
                        }
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Today's recipe — just for you")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)
                            .textCase(.uppercase)
                            .kerning(0.5)

                        Text(recipe.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(recipe.localizedDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            RecipeChip(icon: "clock", text: "\(recipe.prepTime)m prep")
                            RecipeChip(icon: "flame", text: "\(recipe.cookTime)m cook")
                            RecipeChip(icon: "person.2", text: "\(recipe.servings) servings")
                        }
                        .padding(.top, 2)
                    }

                    lockedSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }

            ctaButton
        }
    }

    // MARK: - Locked placeholder

    private var lockedSection: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("Ingredients")
                    .font(.title3)
                    .fontWeight(.bold)

                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                        .frame(height: 14)
                        .frame(maxWidth: i == 4 ? .infinity * 0.6 : .infinity)
                }

                Text("Instructions")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.top, 6)

                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                        .frame(height: 14)
                        .frame(maxWidth: .infinity)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 14)
                        .frame(maxWidth: .infinity)
                }
            }
            .blur(radius: 5)

            VStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.accentColor)
                Text("Start your free trial to unlock\ningredients & steps")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Fallback (no matching recipe)

    private var fallbackCard: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)
                VStack(spacing: 8) {
                    Text("Your recipe is on its way")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    Text("A personalized recipe will be waiting for you each day.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.horizontal, 32)
            Spacer()
            ctaButton
        }
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            HapticManager.impact(.medium)
            viewModel.nextPage()
        } label: {
            Text("Unlock My Recipe")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 32)
        .background(.regularMaterial)
    }
}

private struct RecipeChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption)
            Text(text).font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}
