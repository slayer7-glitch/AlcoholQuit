import XCTest

@MainActor
final class ScreenshotTests: XCTestCase {
    func testCaptureScreens() throws {
        continueAfterFailure = false
        let screens = [
            ("01-onboarding", "onboarding", "Welcome"),
            ("02-home", "home", "Today"),
            ("03-check-in", "check-in", "Check in"),
            ("04-craving-support", "craving-support", "Craving support"),
            ("05-progress", "progress", "Your progress"),
            ("06-settings", "settings", "Settings"),
            ("07-authentication", "authentication", "Account & sync"),
            ("08-safety", "safety", "Safety & help")
        ]
        for (name, route, title) in screens {
            let app = XCUIApplication()
            app.launchArguments = ["--screenshot-screen", route, "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
            app.launch()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 15), "Screen failed to load: \(route)")
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
            app.terminate()
        }
    }
}
