import XCTest

final class JourneyTests: XCTestCase {
    @MainActor func testOnboardingSaveSearchPickAndPersistence() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset"]
        app.launch()
        for _ in 0..<3 { XCTAssertTrue(app.buttons["onboardingNext"].waitForExistence(timeout: 5)); app.buttons["onboardingNext"].tap() }
        XCTAssertTrue(app.buttons["addRecommendation"].waitForExistence(timeout: 5))
        app.buttons["addRecommendation"].tap()
        let title = app.textFields["titleField"]
        if title.waitForExistence(timeout: 3) { title.tap(); title.typeText("The Grand Budapest Hotel") }
        else { let area = app.textViews["titleField"]; XCTAssertTrue(area.waitForExistence(timeout: 3)); area.tap(); area.typeText("The Grand Budapest Hotel") }
        app.textFields["personField"].tap(); app.textFields["personField"].typeText("Mia")
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }
        app.swipeUp()
        XCTAssertTrue(app.buttons["saveRecommendation"].waitForExistence(timeout: 3)); app.buttons["saveRecommendation"].tap()
        XCTAssertTrue(app.staticTexts["The Grand Budapest Hotel"].waitForExistence(timeout: 5))
        let search = app.textFields["librarySearch"]; search.tap(); search.typeText("Mia")
        XCTAssertTrue(app.staticTexts["The Grand Budapest Hotel"].exists)
        app.terminate(); app.launchArguments = ["--ui-testing"]; app.launch()
        XCTAssertTrue(app.staticTexts["The Grand Budapest Hotel"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Pick for me"].tap()
        app.buttons["shufflePick"].tap()
        XCTAssertTrue(app.staticTexts["The Grand Budapest Hotel"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Collections"].tap()
        app.buttons["newCollection"].tap()
        app.textFields["collectionName"].tap(); app.textFields["collectionName"].typeText("Film nights")
        app.buttons["saveCollection"].tap()
        XCTAssertTrue(app.staticTexts["Film nights"].waitForExistence(timeout: 5))
    }
    @MainActor func testScreenshotLibrary() {
        let app = XCUIApplication(); app.launchArguments = ["--screenshots"]; app.launch()
        XCTAssertTrue(app.staticTexts["Perfect Days"].waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "Saved recommendations"; shot.lifetime = .keepAlways; add(shot)
        app.tabBars.buttons["Pick for me"].tap(); app.buttons["shufflePick"].tap()
        XCTAssertTrue(app.buttons["shufflePick"].waitForExistence(timeout: 5))
    }
    @MainActor func testDetailTriedAndScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = ["--screenshots"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Perfect Days"].waitForExistence(timeout: 5))
        capture(app, "saved")
        app.staticTexts["Perfect Days"].tap()
        XCTAssertTrue(app.buttons["toggleTried"].waitForExistence(timeout: 5))
        capture(app, "detail")
        app.swipeUp()
        app.buttons["toggleTried"].tap()
        XCTAssertTrue(app.buttons["toggleTried"].label.contains("Move back"))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Pick for me"].tap()
        capture(app, "pick")
        app.buttons["shufflePick"].tap()
        XCTAssertFalse(app.staticTexts["Perfect Days"].exists)
        app.tabBars.buttons["Collections"].tap()
        capture(app, "collections")
        app.staticTexts["A slow weekend"].tap()
        XCTAssertTrue(app.buttons["shareCollection"].waitForExistence(timeout: 5))
        app.buttons["shareCollection"].tap()
        XCTAssertTrue(app.staticTexts["Save to Files"].waitForExistence(timeout: 5))
    }

    @MainActor func testWelcomeScreenshot() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--reset"]; app.launch()
        XCTAssertTrue(app.buttons["onboardingNext"].waitForExistence(timeout: 5))
        capture(app, "onboarding")
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

}
