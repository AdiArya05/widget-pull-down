import XCTest

final class FitnessPrototypeUITests: XCTestCase {
    @MainActor
    func testCornerPullsAndReturn() {
        let app = XCUIApplication()
        app.launch()

        let fitness = app.buttons["fitness-widget"]
        let collapse = app.buttons["widget-collapse"]
        XCTAssertTrue(fitness.waitForExistence(timeout: 5))
        attachScreenshot("Fitness widget")

        let right = CGVector(dx: 0.933, dy: 0.292)
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

        XCTAssertFalse(app.buttons["select-weather"].exists)
        XCTAssertFalse(app.buttons["select-home"].exists)
    }

    @MainActor
    func testStocksChartAndReturn() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["fitness-widget"].waitForExistence(timeout: 5))
        let collapse = app.buttons["widget-collapse"]
        let expandedHook = CGVector(dx: 0.94, dy: 0.961)

        app.buttons["select-stocks"].tap()
        let stocks = app.buttons["stocks-widget"]
        XCTAssertTrue(stocks.waitForExistence(timeout: 3))
        attachScreenshot("Stocks widget")
        drag(in: app, from: CGVector(dx: 0.46, dy: 0.292), toY: 0.97, velocity: 620)

        let chart = app.descendants(matching: .any)["stocks-chart"]
        XCTAssertTrue(chart.waitForExistence(timeout: 3))
        let start = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.60))
        let end = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.60))
        start.tap()
        let firstPrice = chart.value as? String
        XCTAssertTrue(firstPrice?.hasPrefix("$") == true)
        start.press(forDuration: 0.1, thenDragTo: end)
        let lastPrice = chart.value as? String
        XCTAssertTrue(lastPrice?.hasPrefix("$") == true)
        XCTAssertNotEqual(firstPrice, lastPrice)
        attachScreenshot("Stocks scrubbed")
        drag(in: app, from: expandedHook, toY: 0.29, velocity: 620)
        XCTAssertTrue(stocks.waitForExistence(timeout: 3))
        XCTAssertFalse(collapse.exists)
        app.buttons["select-fitness"].tap()
        XCTAssertTrue(app.buttons["fitness-widget"].waitForExistence(timeout: 3))
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
