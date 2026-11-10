# Widget Pull-down

An iPhone prototype for expanding Fitness, Weather, Home, and Stocks widgets into full-screen views. The demos use sample artwork from screenshots.

Open `FitnessPrototype.xcodeproj` and run the `FitnessPrototype` scheme with Xcode and the iOS 27 SDK. For a physical iPhone, select your Apple development team under Signing & Capabilities.

- Use the selector above the dock to switch widgets.
- Pull down from a lower corner to expand the widget.
- Pull up from the bottom-right handle to collapse it again.

The `FitnessPrototypeUITests` target exercises both gestures and the widget selector.

The Home demo uses a [captured Apple Home widget](https://9to5mac.com/2023/06/12/ios-17-home-app-widgets/) and [Apple’s Living Room screen](https://support.apple.com/library/content/dam/edam/applecare/images/en_US/homepod/ios14-iphone11-pro-home-organize-accessories-in-room.jpg). Tap the lamp or either scene to change the simulated light. The Stocks demo uses Apple’s [Stocks widget](https://developer.apple.com/design/human-interface-guidelines/widgets) and [AAPL chart](https://developer.apple.com/design/human-interface-guidelines/charting-data) artwork. Drag across the chart to inspect its sample values.
