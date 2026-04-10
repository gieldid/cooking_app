import XCTest
@testable import CookingApp

@MainActor
final class OnboardingViewModelTests: XCTestCase {

    private var vm: OnboardingViewModel!

    override func setUp() {
        super.setUp()
        vm = OnboardingViewModel()
    }

    // MARK: - Page navigation

    func testStartsOnFirstPage() {
        XCTAssertEqual(vm.currentPage, 0)
    }

    func testNextPageIncrements() {
        vm.nextPage()
        XCTAssertEqual(vm.currentPage, 1)
    }

    func testNextPageDoesNotExceedTotalPages() {
        for _ in 0..<20 { vm.nextPage() }
        XCTAssertEqual(vm.currentPage, vm.totalPages - 1)
    }

    func testPreviousPageDecrements() {
        vm.nextPage()
        vm.nextPage()
        vm.previousPage()
        XCTAssertEqual(vm.currentPage, 1)
    }

    func testPreviousPageDoesNotGoBelowZero() {
        vm.previousPage()
        XCTAssertEqual(vm.currentPage, 0)
    }

    func testCanAdvanceIsFalseOnLastPage() {
        for _ in 0..<vm.totalPages { vm.nextPage() }
        XCTAssertFalse(vm.canAdvance)
    }

    func testCanAdvanceIsTrueOnFirstPage() {
        XCTAssertTrue(vm.canAdvance)
    }

    func testTotalPagesIsCorrect() {
        XCTAssertEqual(vm.totalPages, 7)
    }

    // MARK: - Allergy toggles

    func testToggleAllergyAdds() {
        vm.toggleAllergy(.nuts)
        XCTAssertTrue(vm.selectedAllergies.contains(.nuts))
    }

    func testToggleAllergyRemoves() {
        vm.toggleAllergy(.nuts)
        vm.toggleAllergy(.nuts)
        XCTAssertFalse(vm.selectedAllergies.contains(.nuts))
    }

    func testToggleMultipleAllergies() {
        vm.toggleAllergy(.nuts)
        vm.toggleAllergy(.dairy)
        XCTAssertEqual(vm.selectedAllergies, [.nuts, .dairy])
    }

    func testStartsWithNoAllergies() {
        XCTAssertTrue(vm.selectedAllergies.isEmpty)
    }

    // MARK: - Diet toggles

    func testToggleDietAdds() {
        vm.toggleDiet(.vegan)
        XCTAssertTrue(vm.selectedDiets.contains(.vegan))
    }

    func testToggleDietRemoves() {
        vm.toggleDiet(.vegan)
        vm.toggleDiet(.vegan)
        XCTAssertFalse(vm.selectedDiets.contains(.vegan))
    }

    func testStartsWithNoDiets() {
        XCTAssertTrue(vm.selectedDiets.isEmpty)
    }

    // MARK: - Difficulty toggles

    func testToggleDifficultyAdds() {
        vm.toggleDifficulty(.easy)
        XCTAssertTrue(vm.selectedDifficulties.contains(.easy))
    }

    func testToggleDifficultyRemoves() {
        vm.toggleDifficulty(.easy)
        vm.toggleDifficulty(.easy)
        XCTAssertFalse(vm.selectedDifficulties.contains(.easy))
    }

    func testStartsWithNoDifficulties() {
        XCTAssertTrue(vm.selectedDifficulties.isEmpty)
    }

    // MARK: - Max duration default

    func testDefaultMaxDurationIsAny() {
        XCTAssertEqual(vm.maxDuration, .any)
    }

    // MARK: - Global difficulties forwarded from protocol

    func testGlobalDifficultiesMatchSelectedDifficulties() {
        vm.toggleDifficulty(.medium)
        XCTAssertEqual(vm.globalDifficulties, vm.selectedDifficulties)
    }

    // MARK: - Per-day overrides

    func testSetPerDayDurationCreatesOverride() {
        vm.setPerDayDuration(weekday: 2, duration: .thirty)
        XCTAssertEqual(vm.perDayOverrides[2]?.maxDuration, .thirty)
    }

    func testClearPerDayOverrideRemovesIt() {
        vm.setPerDayDuration(weekday: 2, duration: .thirty)
        vm.clearPerDayOverride(weekday: 2)
        XCTAssertNil(vm.perDayOverrides[2])
    }

    func testTogglePerDayDifficultyAdds() {
        vm.togglePerDayDifficulty(weekday: 3, difficulty: .hard)
        XCTAssertTrue(vm.perDayOverrides[3]?.difficulties.contains(.hard) == true)
    }

    func testTogglePerDayDifficultyRemoves() {
        vm.togglePerDayDifficulty(weekday: 3, difficulty: .hard)
        vm.togglePerDayDifficulty(weekday: 3, difficulty: .hard)
        XCTAssertFalse(vm.perDayOverrides[3]?.difficulties.contains(.hard) == true)
    }
}
