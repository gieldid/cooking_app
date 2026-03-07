import XCTest

// MARK: - App Store Screenshot Tests
//
// These tests drive the app through key screens and call snapshot() at each one.
// SnapshotHelper.swift (from Fastlane) must be added to this target alongside this file.
//
// Run via:  fastlane screenshots
// Or:       xcodebuild test -scheme CookingApp -destination "name=iPhone 17 Pro Max"

@MainActor
final class CookingAppUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication(bundleIdentifier: "nl.gieljurriens.inkgredients")
        setupSnapshot(app)
        app.launchArguments = [
            "--screenshots",          // activates mock data + skips splash/RevenueCat
            "-hasCompletedOnboarding", "YES",  // UserDefaults override → skip onboarding
        ]
        app.launch()
    }

    func testScreenshots() throws {
        // Debug: capture whatever is on screen immediately after launch
        sleep(3)
        snapshot("00_debug_launch")

        // ── 1. Home – Today's Recipe ──────────────────────────────────────────
        // Use a broad descendant query so the element is found regardless of whether
        // NavigationLink registers as a button or another type in the accessibility tree.
        let cookButton = app.descendants(matching: .any).matching(identifier: "btn_cook").firstMatch
        XCTAssert(cookButton.waitForExistence(timeout: 15), "Cook button not found on Home tab")
        sleep(2) // wait for appear animations to finish
        snapshot("01_today")

        // ── 2. Recipe Detail ──────────────────────────────────────────────────
        cookButton.tap()
        sleep(2)
        snapshot("02_recipe_detail")

        // Scroll down to show ingredients section
        app.swipeUp()
        sleep(2)
        snapshot("03_recipe_ingredients")

        // Back to Home
        app.navigationBars.buttons.firstMatch.tap()
        sleep(2)

        // ── 3. Shopping List ──────────────────────────────────────────────────
        // Tab bar order: 0=Today, 1=Shopping, 2=Favourites, 3=Settings
        app.tabBars.firstMatch.buttons.element(boundBy: 1).tap()
        sleep(2)
        snapshot("04_shopping_list")

        // ── 4. Favourites ─────────────────────────────────────────────────────
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        sleep(2)
        snapshot("05_favourites")
    }
}
