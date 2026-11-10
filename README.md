# Widget Pull-down

An iPhone prototype for expanding Fitness and Stocks widgets into full-screen views. The artwork comes from iPhone captures. The AAPL graph and scrubber use samples traced from the supplied chart.

Open `FitnessPrototype.xcodeproj` and run the `FitnessPrototype` scheme with Xcode and the iOS 27 SDK. For a physical iPhone, select your Apple development team under Signing & Capabilities.

- Use the selector above the dock to switch widgets.
- Pull down from a lower corner to expand the widget.
- Drag across the expanded AAPL chart to inspect prices.
- Pull up from the bottom-right handle to collapse the panel.

The `FitnessPrototypeUITests` target exercises the selector, gestures, and chart scrubber.
