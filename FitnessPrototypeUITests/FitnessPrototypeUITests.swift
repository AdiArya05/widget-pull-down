import XCTest

final class FitnessPrototypeUITests: XCTestCase {
    @MainActor
    func testCornerPullsAndReturn() {
        let app = XCUIApplication()
        app.launch()

        let fitness = app.buttons["fitness-widget"]
        let weather = app.buttons["weather-widget"]
        let collapse = app.buttons["widget-collapse"]
        XCTAssertTrue(fitness.waitForExistence(timeout: 5))
        attachScreenshot("Fitness widget")

        let right = CGVector(dx: 0.933, dy: 0.292)
        let left = CGVector(dx: 0.10, dy: 0.281)
        let center = CGVector(dx: 0.50, dy: 0.281)
        let expandedHook = CGVector(dx: 0.94, dy: 0.961)

        drag(in: app, from: center, toY: 0.955, velocity: 650)
        XCTAssertTrue(fitness.exists)
        XCTAssertFalse(collapse.exists)

        drag(in: app, from: right, toY: 0.43, velocity: 340)
        XCTAssertTrue(fitness.exists)
        XCTAssertFalse(collapse.exists)

        drag(in: app, from: right, toY: 0.97, velocity: 620)
        XCTAssertTrue(collapse.waitForExistence(timeout: 3))
        XCTAssertFalse(fitness.exists)
        attachScreenshot("Fitness expanded")

        drag(in: app, from: expandedHook, toY: 0.88, velocity: 290)
        XCTAssertTrue(collapse.exists)

        drag(in: app, from: expandedHook, toY: 0.29, velocity: 620)
        XCTAssertTrue(fitness.waitForExistence(timeout: 3))
        XCTAssertFalse(collapse.exists)

        app.buttons["select-weather"].tap()
        XCTAssertTrue(weather.waitForExistence(timeout: 3))
        attachScreenshot("Weather widget")

        drag(in: app, from: left, toY: 0.97, velocity: 620)
        XCTAssertTrue(collapse.waitForExistence(timeout: 3))
        XCTAssertFalse(weather.exists)
        attachScreenshot("Weather expanded")

        drag(in: app, from: expandedHook, toY: 0.29, velocity: 620)
        XCTAssertTrue(weather.waitForExistence(timeout: 3))
        XCTAssertFalse(collapse.exists)
    }

    @MainActor
    private func drag(in app: XCUIApplication, from start: CGVector, toY: CGFloat, velocity: CGFloat) {
        app.coordinate(withNormalizedOffset: start).press(
            forDuration: 0.08,
            thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: start.dx, dy: toY)),
            withVelocity: XCUIGestureVelocity(rawValue: velocity),
            thenHoldForDuration: 0
        )
    }

    @MainActor
    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
