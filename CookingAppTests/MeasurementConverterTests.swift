import XCTest
@testable import CookingApp

final class MeasurementConverterTests: XCTestCase {

    // MARK: - Metric output (imperial → metric)

    func testCupsToMl() {
        let r = MeasurementConverter.display(amount: "2", unit: "cups", scaleFactor: 1, preference: .metric)
        XCTAssertEqual(r.amount, "480")
        XCTAssertEqual(r.unit, "ml")
    }

    func testCupsToLiters() {
        let r = MeasurementConverter.display(amount: "5", unit: "cups", scaleFactor: 1, preference: .metric)
        XCTAssertEqual(r.amount, "1.2")
        XCTAssertEqual(r.unit, "L")
    }

    func testTablespoonToMl() {
        let r = MeasurementConverter.display(amount: "3", unit: "tbsp", scaleFactor: 1, preference: .metric)
        XCTAssertEqual(r.amount, "45")
        XCTAssertEqual(r.unit, "ml")
    }

    func testOuncesToGrams() {
        let r = MeasurementConverter.display(amount: "4", unit: "oz", scaleFactor: 1, preference: .metric)
        XCTAssertEqual(r.amount, "113")
        XCTAssertEqual(r.unit, "g")
    }

    func testPoundsToKg() {
        let r = MeasurementConverter.display(amount: "3", unit: "lb", scaleFactor: 1, preference: .metric)
        XCTAssertEqual(r.amount, "1.4")
        XCTAssertEqual(r.unit, "kg")
    }

    func testPoundsToGramsWhenUnderKg() {
        let r = MeasurementConverter.display(amount: "1", unit: "lb", scaleFactor: 1, preference: .metric)
        XCTAssertEqual(r.unit, "g")
    }

    // MARK: - Imperial output (metric → imperial)

    func testMlToCups() {
        let r = MeasurementConverter.display(amount: "480", unit: "ml", scaleFactor: 1, preference: .imperial)
        XCTAssertEqual(r.amount, "2")
        XCTAssertEqual(r.unit, "cups")
    }

    func testMlToTbsp() {
        let r = MeasurementConverter.display(amount: "30", unit: "ml", scaleFactor: 1, preference: .imperial)
        XCTAssertEqual(r.amount, "2")
        XCTAssertEqual(r.unit, "tbsp")
    }

    func testGramsToOz() {
        let r = MeasurementConverter.display(amount: "100", unit: "g", scaleFactor: 1, preference: .imperial)
        XCTAssertEqual(r.amount, "3.5")
        XCTAssertEqual(r.unit, "oz")
    }

    func testKgToLb() {
        let r = MeasurementConverter.display(amount: "1", unit: "kg", scaleFactor: 1, preference: .imperial)
        XCTAssertEqual(r.amount, "2.2")
        XCTAssertEqual(r.unit, "lb")
    }

    // MARK: - Scale factor

    func testScaleFactorApplied() {
        let r = MeasurementConverter.display(amount: "1", unit: "cups", scaleFactor: 3, preference: .metric)
        XCTAssertEqual(r.amount, "720")
        XCTAssertEqual(r.unit, "ml")
    }

    func testScaleFactorHalf() {
        let r = MeasurementConverter.display(amount: "2", unit: "cups", scaleFactor: 0.5, preference: .metric)
        XCTAssertEqual(r.amount, "240")
        XCTAssertEqual(r.unit, "ml")
    }

    // MARK: - Non-convertible units pass through

    func testClovePassesThrough() {
        let r = MeasurementConverter.display(amount: "3", unit: "cloves", scaleFactor: 1, preference: .metric)
        XCTAssertEqual(r.amount, "3")
        XCTAssertEqual(r.unit, "cloves")
    }

    func testNonNumericAmountPassesThrough() {
        let r = MeasurementConverter.display(amount: "pinch", unit: "salt", scaleFactor: 1, preference: .metric)
        XCTAssertEqual(r.amount, "pinch")
        XCTAssertEqual(r.unit, "salt")
    }

    // MARK: - Formatting

    func testIntegerHasNoDecimalPoint() {
        let r = MeasurementConverter.display(amount: "2", unit: "cloves", scaleFactor: 1, preference: .metric)
        XCTAssertFalse(r.amount.contains("."))
    }

    func testDecimalHasOneDecimalPlace() {
        let r = MeasurementConverter.display(amount: "3", unit: "lb", scaleFactor: 1, preference: .metric)
        let parts = r.amount.split(separator: ".")
        XCTAssertEqual(parts.count, 2)
        XCTAssertEqual(parts[1].count, 1)
    }

    // MARK: - Case insensitivity

    func testUnitLookupIsCaseInsensitive() {
        let lower = MeasurementConverter.display(amount: "1", unit: "cup", scaleFactor: 1, preference: .metric)
        let upper = MeasurementConverter.display(amount: "1", unit: "Cup", scaleFactor: 1, preference: .metric)
        XCTAssertEqual(lower.amount, upper.amount)
        XCTAssertEqual(lower.unit, upper.unit)
    }
}
