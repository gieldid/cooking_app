import SwiftUI
import UIKit

struct RecipeDetailView: View {
    let recipe: Recipe
    @Binding var servingsMultiplier: Int
    @State private var completedSteps: Set<Int> = []
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        Task { @MainActor in
                            await buildShareItems()
                            if !shareItems.isEmpty { showShareSheet = true }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }

                    Button {
                        prefs.toggleFavourite(recipe)
                    } label: {
                        Image(systemName: prefs.isFavourite(recipe) ? "heart.fill" : "heart")
                            .foregroundStyle(prefs.isFavourite(recipe) ? .red : .primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityShareSheet(items: shareItems)
                .ignoresSafeArea()
        }
    }

    @MainActor
    private func buildShareItems() async {
        var items: [Any] = []
        var preloadedImage: UIImage? = nil
        if let urlString = recipe.imageURL, let url = URL(string: urlString) {
            preloadedImage = try? await fetchUIImage(from: url)
        }
        let card = RecipeShareCard(recipe: recipe, preloadedImage: preloadedImage)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            items.append(uiImage)
        }
        if let recipeId = recipe.id,
           let deepLink = URL(string: "inkgredients://recipe/\(recipeId)") {
            items.append(deepLink)
        }
        shareItems = items
    }

    private func fetchUIImage(from url: URL) async throws -> UIImage? {
        let (data, _) = try await URLSession.shared.data(from: url)
        return UIImage(data: data)
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

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct RecipeShareCard: View {
    let recipe: Recipe
    let preloadedImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            // Recipe image
            if let uiImage = preloadedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 360, height: 210)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.7), Color.accentColor.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 360, height: 210)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 52))
                        .foregroundStyle(.white.opacity(0.8))
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(recipe.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(recipe.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 16) {
                    Label("\(recipe.totalTime) min", systemImage: "clock")
                    Label("\(recipe.servings) servings", systemImage: "person.2")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 10) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Inkgredients")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(String(localized: "Get the full recipe on Inkgredients"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
        }
        .frame(width: 360)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
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
