import XCTest

@MainActor
final class OnboardingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication(bundleIdentifier: "nl.gieljurriens.inkgredients")
    }

    // MARK: - Onboarding

    /// Welcome screen appears when onboarding has not been completed.
    func testWelcomeScreenAppearsForNewUser() {
        app.launchArguments = ["-hasCompletedOnboarding", "NO"]
        app.launch()

        XCTAssert(
            app.buttons["Get Started"].waitForExistence(timeout: 5),
            "Expected 'Get Started' button on welcome screen"
        )
    }

    /// Progress bar capsules are visible on the welcome screen.
    func testProgressIndicatorIsVisible() {
        app.launchArguments = ["-hasCompletedOnboarding", "NO"]
        app.launch()

        XCTAssert(app.buttons["Get Started"].waitForExistence(timeout: 5))
        // Accessibility label set in OnboardingContainerView
        XCTAssert(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Step'")).firstMatch.waitForExistence(timeout: 3))
    }

    /// Tapping 'Get Started' advances to the Allergies step.
    func testGetStartedAdvancesToAllergies() {
        app.launchArguments = ["-hasCompletedOnboarding", "NO"]
        app.launch()

        app.buttons["Get Started"].waitForExistence(timeout: 5)
        app.buttons["Get Started"].tap()

        XCTAssert(
            app.staticTexts["Allergies"].waitForExistence(timeout: 3),
            "Expected Allergies screen after tapping Get Started"
        )
    }

    /// Tapping through the full onboarding flow without any selections reaches the subscription screen.
    func testFullOnboardingFlowReachesSubscription() {
        app.launchArguments = ["-hasCompletedOnboarding", "NO"]
        app.launch()

        // Welcome
        XCTAssert(app.buttons["Get Started"].waitForExistence(timeout: 5))
        app.buttons["Get Started"].tap()

        // Allergies → Continue
        XCTAssert(app.buttons["Continue"].waitForExistence(timeout: 3))
        app.buttons["Continue"].tap()

        // Dietary Preferences → Continue
        XCTAssert(app.buttons["Continue"].waitForExistence(timeout: 3))
        app.buttons["Continue"].tap()

        // Recipe Preferences → Continue
        XCTAssert(app.buttons["Continue"].waitForExistence(timeout: 3))
        app.buttons["Continue"].tap()

        // Notifications → Skip
        XCTAssert(app.buttons["Skip Notifications"].waitForExistence(timeout: 3))
        app.buttons["Skip Notifications"].tap()

        // Recipe Reveal — wait up to 15s for Firestore fetch
        XCTAssert(app.buttons["Unlock My Recipe"].waitForExistence(timeout: 15))
        app.buttons["Unlock My Recipe"].tap()

        // Subscription screen
        let trialText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Trial' OR label CONTAINS 'Subscribe'")).firstMatch
        XCTAssert(trialText.waitForExistence(timeout: 5), "Expected subscription screen")
    }

    // MARK: - Tab navigation

    /// All four tabs are accessible and show their navigation title.
    func testTabBarNavigationBetweenAllTabs() {
        app.launchArguments = [
            "--screenshots",
            "-hasCompletedOnboarding", "YES"
        ]
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssert(tabBar.waitForExistence(timeout: 10), "Tab bar not found")

        // Shopping tab
        tabBar.buttons.element(boundBy: 1).tap()
        XCTAssert(
            app.navigationBars["Shopping List"].waitForExistence(timeout: 5),
            "Expected Shopping List nav bar"
        )

        // Favourites tab
        tabBar.buttons.element(boundBy: 2).tap()
        XCTAssert(
            app.navigationBars["Favourites"].waitForExistence(timeout: 5),
            "Expected Favourites nav bar"
        )

        // Settings tab
        tabBar.buttons.element(boundBy: 3).tap()
        XCTAssert(
            app.navigationBars["Settings"].waitForExistence(timeout: 5),
            "Expected Settings nav bar"
        )

        // Back to Today
        tabBar.buttons.element(boundBy: 0).tap()
        XCTAssert(
            app.navigationBars["Today's Recipe"].waitForExistence(timeout: 5),
            "Expected Today's Recipe nav bar"
        )
    }

    /// Navigating back to Today after visiting Shopping does not trigger a loading spinner.
    func testTodayTabDoesNotRefetchOnReturn() {
        app.launchArguments = [
            "--screenshots",
            "-hasCompletedOnboarding", "YES"
        ]
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssert(tabBar.waitForExistence(timeout: 10))

        // Wait for the initial recipe to load
        XCTAssert(app.descendants(matching: .any).matching(identifier: "btn_cook").firstMatch.waitForExistence(timeout: 20))

        // Switch to Shopping and back
        tabBar.buttons.element(boundBy: 1).tap()
        tabBar.buttons.element(boundBy: 0).tap()

        // Cook button should still be visible immediately — no loading state
        let cookBtn = app.descendants(matching: .any).matching(identifier: "btn_cook").firstMatch
        XCTAssert(cookBtn.exists, "Cook button should still be visible after returning to Today tab — no refetch expected")
    }

    // MARK: - Recipe detail

    /// Tapping 'Let's Cook!' navigates to the recipe detail screen.
    func testCookButtonOpensRecipeDetail() {
        app.launchArguments = [
            "--screenshots",
            "-hasCompletedOnboarding", "YES"
        ]
        app.launch()

        let cookBtn = app.descendants(matching: .any).matching(identifier: "btn_cook").firstMatch
        XCTAssert(cookBtn.waitForExistence(timeout: 20))
        cookBtn.tap()

        // Recipe detail has a favourite button in the toolbar
        XCTAssert(
            app.buttons["btn_favourite"].waitForExistence(timeout: 5),
            "Expected to be on recipe detail screen"
        )
    }
}
