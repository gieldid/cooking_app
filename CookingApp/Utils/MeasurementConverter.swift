import Foundation

enum MeasurementConverter {

    // MARK: - Lookup tables

    private static let imperialVolumeToML: [String: Double] = [
        "cup": 240, "cups": 240,
        "tablespoon": 15, "tablespoons": 15, "tbsp": 15,
        "teaspoon": 5, "teaspoons": 5, "tsp": 5,
        "fl oz": 29.57, "fluid ounce": 29.57, "fluid ounces": 29.57,
    ]

    private static let imperialWeightToG: [String: Double] = [
        "oz": 28.35, "ounce": 28.35, "ounces": 28.35,
        "lb": 453.59, "lbs": 453.59, "pound": 453.59, "pounds": 453.59,
    ]

    private static let metricVolumeToML: [String: Double] = [
        "ml": 1, "milliliter": 1, "milliliters": 1, "millilitre": 1, "millilitres": 1,
        "l": 1000, "liter": 1000, "liters": 1000, "litre": 1000, "litres": 1000,
    ]

    private static let metricWeightToG: [String: Double] = [
        "g": 1, "gram": 1, "grams": 1,
        "kg": 1000, "kilogram": 1000, "kilograms": 1000,
    ]

    // MARK: - Public API

    /// Returns a display-ready (amount, unit) pair, applying scaling and unit conversion.
    static func display(
        amount: String,
        unit: String,
        scaleFactor: Double = 1.0,
        preference: MeasurementPreference
    ) -> (amount: String, unit: String) {
        guard let value = Double(amount) else { return (amount, unit) }
        let scaled = value * scaleFactor
        let lower = unit.lowercased().trimmingCharacters(in: .whitespaces)

        if preference.usesMetric {
            if let factor = imperialVolumeToML[lower] {
                let ml = scaled * factor
                return ml >= 1000 ? (format(ml / 1000), "L") : (format(ml), "ml")
            }
            if let factor = imperialWeightToG[lower] {
                let g = scaled * factor
                return g >= 1000 ? (format(g / 1000), "kg") : (format(g), "g")
            }
        } else {
            if let factor = metricVolumeToML[lower] {
                let ml = scaled * factor
                if ml >= 240 { return (format(ml / 240), "cups") }
                if ml >= 15  { return (format(ml / 15),  "tbsp") }
                return (format(ml / 5), "tsp")
            }
            if let factor = metricWeightToG[lower] {
                let g = scaled * factor
                return g >= 453.59 ? (format(g / 453.59), "lb") : (format(g / 28.35), "oz")
            }
        }

        // Unit is already in the right system, or non-convertible (pinch, clove, piece…)
        return (format(scaled), unit)
    }

    // MARK: - Helpers

    private static func format(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return rounded == rounded.rounded()
            ? String(format: "%.0f", rounded)
            : String(format: "%.1f", rounded)
    }
}
