import SwiftUI
import UIKit
import LinkPresentation

struct RecipeDetailView: View {
    let recipe: Recipe
    @Binding var servingsMultiplier: Int
    @State private var completedSteps: Set<Int> = []
    @State private var showShareSheet = false
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

                    if let nutrition = recipe.nutrition {
                        NutritionCard(nutrition: nutrition)
                    }

                    Divider()

                    // Servings adjuster
                    HStack {
                        Text("Servings")
                            .font(.headline)
                        Spacer()
                        Stepper(String(servingsMultiplier), value: $servingsMultiplier, in: 1...20)
                        .accessibilityLabel("Servings")
                        .accessibilityValue("\(servingsMultiplier) servings")
                        .accessibilityHint("Adjust number of servings")
                    }

                    Divider()

                    // Ingredients
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.title2)
                            .fontWeight(.bold)

                        ForEach(recipe.localizedIngredients) { ingredient in
                            let disp = displayIngredient(ingredient)
                            HStack(alignment: .center, spacing: 12) {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 6, height: 6)

                                Text(verbatim: "\(disp.amount) \(disp.unit) \(ingredient.name)")
                                    .fixedSize(horizontal: false, vertical: true)
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
                    if recipe.id != nil {
                        Button {
                            HapticManager.impact(.light)
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Share recipe")
                        .sheet(isPresented: $showShareSheet) {
                            ActivityShareSheet(recipe: recipe)
                                .ignoresSafeArea()
                        }
                    }

                    Button {
                        HapticManager.impact(.medium)
                        prefs.toggleFavourite(recipe)
                    } label: {
                        Image(systemName: prefs.isFavourite(recipe) ? "heart.fill" : "heart")
                            .foregroundStyle(prefs.isFavourite(recipe) ? .red : .primary)
                    }
                    .accessibilityLabel(prefs.isFavourite(recipe) ? "Remove from favourites" : "Add to favourites")
                    .accessibilityIdentifier("btn_favourite")
                }
            }
        }
        .trackScreenTime("recipe_detail")
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
            .accessibilityHidden(true)
    }
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let recipe: Recipe

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let source = RecipeLinkItemSource(recipe: recipe)
        return UIActivityViewController(activityItems: [source], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private final class RecipeLinkItemSource: NSObject, UIActivityItemSource {
    private let recipe: Recipe
    private let url: URL?

    init(recipe: Recipe) {
        self.recipe = recipe
        if let id = recipe.id {
            self.url = URL(string: "https://gieljurriens.nl/inkgredients/recipe/\(id)")
        } else {
            self.url = nil
        }
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        url as Any
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        url
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = recipe.title
        if let icon = UIImage(named: "ChefMascot") {
            metadata.imageProvider = NSItemProvider(object: icon)
        }
        return metadata
    }
}

private struct NutritionCard: View {
    let nutrition: Nutrition

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Nutrition per serving")
                    .font(.headline)
                Spacer()
                Text("Estimated values")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                MacroCell(label: "Calories", value: "\(nutrition.calories)", unit: "kcal")
                Divider().frame(height: 40)
                MacroCell(label: "Protein", value: "\(nutrition.protein)", unit: "g")
                Divider().frame(height: 40)
                MacroCell(label: "Carbs", value: "\(nutrition.carbs)", unit: "g")
                Divider().frame(height: 40)
                MacroCell(label: "Fat", value: "\(nutrition.fat)", unit: "g")
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct MacroCell: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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

    @State private var timeRemaining: Int = 0
    @State private var isRunning = false
    @State private var isFinished = false

    private static let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var detectedSeconds: Int? { parseStepSeconds(text) }

    var body: some View {
        Button {
            HapticManager.impact(.light)
            onToggle()
        } label: {
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
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(text)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .strikethrough(isCompleted)
                        .foregroundStyle(isCompleted ? .secondary : .primary)

                    if detectedSeconds != nil {
                        StepTimerButton(
                            timeRemaining: timeRemaining,
                            isRunning: isRunning,
                            isFinished: isFinished
                        ) {
                            if isFinished {
                                timeRemaining = detectedSeconds ?? 0
                                isFinished = false
                                isRunning = false
                            } else {
                                HapticManager.impact(.medium)
                                isRunning.toggle()
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Step \(stepNumber): \(text)")
        .accessibilityValue(isCompleted ? "Completed" : "Not completed")
        .accessibilityHint(isCompleted ? "Double tap to mark as incomplete" : "Double tap to mark as complete")
        .onAppear {
            if let seconds = detectedSeconds { timeRemaining = seconds }
        }
        .onReceive(Self.tick) { _ in
            guard isRunning, timeRemaining > 0 else { return }
            timeRemaining -= 1
            if timeRemaining == 0 {
                isRunning = false
                isFinished = true
                HapticManager.impact(.heavy)
            }
        }
    }
}

private struct StepTimerButton: View {
    let timeRemaining: Int
    let isRunning: Bool
    let isFinished: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                Image(systemName: isFinished ? "checkmark.circle.fill" : (isRunning ? "pause.fill" : "play.fill"))
                    .font(.caption)
                Text(isFinished ? "Done!" : formatTime(timeRemaining))
                    .font(.caption.monospacedDigit())
                    .fontWeight(.medium)
            }
            .foregroundStyle(isFinished ? Color.green : Color.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background((isFinished ? Color.green : Color.accentColor).opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func formatTime(_ seconds: Int) -> String {
        if seconds >= 3600 {
            return String(format: "%d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
        }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private func parseStepSeconds(_ text: String) -> Int? {
    let pattern = #"(\d+)\s*(seconds?|minutes?|hours?|seconden?|secondes?|secondi|secondo|minuten|minuut|minuto|minuti|uren|uur|heures?|stunden?|ore|ora)"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
    let nsText = text as NSString
    let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
    var maxSeconds = 0
    for match in matches {
        guard match.numberOfRanges >= 3,
              let numRange = Range(match.range(at: 1), in: text),
              let unitRange = Range(match.range(at: 2), in: text),
              let number = Int(text[numRange]) else { continue }
        let unit = text[unitRange].lowercased()
        let multiplier: Int
        if unit.hasPrefix("sec") { multiplier = 1 }
        else if unit.hasPrefix("min") { multiplier = 60 }
        else { multiplier = 3600 }
        maxSeconds = max(maxSeconds, number * multiplier)
    }
    return maxSeconds > 0 ? maxSeconds : nil
}
