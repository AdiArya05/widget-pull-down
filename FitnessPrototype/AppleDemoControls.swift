import UIKit

/// Touch targets for the sample room in the Apple Home capture.
@MainActor
final class RoomControls: UIView {
    private let lamp = UIButton(type: .custom)
    private let leave = UIButton(type: .custom)
    private let arrive = UIButton(type: .custom)
    private let lampFill = UIView()
    private let bulb = UIImageView(image: UIImage(systemName: "lightbulb.fill"))
    private let lampTitle = UILabel()
    private let lampStatus = UILabel()
    private var isOn = false

    var lampChanged: ((Bool) -> Void)?

    init() {
        super.init(frame: .zero)
        lamp.accessibilityLabel = "White table lamp"
        lamp.accessibilityIdentifier = "home-lamp"
        leave.accessibilityLabel = "Leave Home"
        leave.accessibilityIdentifier = "home-leave"
        arrive.accessibilityLabel = "I’m Home"
        arrive.accessibilityIdentifier = "home-arrive"
        lamp.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.setLamp(!self.isOn)
        }, for: .touchUpInside)
        leave.addAction(UIAction { [weak self] _ in self?.setLamp(false) }, for: .touchUpInside)
        arrive.addAction(UIAction { [weak self] _ in self?.setLamp(true) }, for: .touchUpInside)
        for button in [lamp, leave, arrive] { addSubview(button) }

        lampFill.backgroundColor = UIColor(white: 0.98, alpha: 1)
        lampFill.layer.cornerCurve = .continuous
        lampFill.isUserInteractionEnabled = false
        bulb.tintColor = .systemYellow
        bulb.contentMode = .scaleAspectFit
        lampTitle.text = "White table\nlamp"
        lampTitle.textColor = .black
        lampTitle.numberOfLines = 2
        lampStatus.text = "100%"
        lampStatus.textColor = .gray
        for view in [bulb, lampTitle, lampStatus] { lampFill.addSubview(view) }
        lamp.addSubview(lampFill)
        lampFill.alpha = 0
        lamp.accessibilityValue = "Off"
        accessibilityElements = [lamp, arrive, leave]
    }

    required init?(coder: NSCoder) { nil }

    static func lampFrame(in bounds: CGRect) -> CGRect {
        scaled(CGRect(x: 0.055, y: 0.593, width: 0.281, height: 0.130), in: bounds)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        lamp.frame = Self.lampFrame(in: bounds)
        leave.frame = scaled(CGRect(x: 0.055, y: 0.368, width: 0.59, height: 0.076), in: bounds)
        arrive.frame = scaled(CGRect(x: 0.055, y: 0.456, width: 0.59, height: 0.076), in: bounds)

        lampFill.frame = lamp.bounds
        lampFill.layer.cornerRadius = lamp.bounds.width * 0.16
        let width = lamp.bounds.width
        bulb.frame = CGRect(x: width * 0.09, y: width * 0.09, width: width * 0.28, height: width * 0.28)
        lampTitle.font = .systemFont(ofSize: width * 0.125, weight: .semibold)
        lampTitle.frame = CGRect(x: width * 0.09, y: width * 0.47, width: width * 0.82, height: width * 0.35)
        lampStatus.font = .systemFont(ofSize: width * 0.12, weight: .medium)
        lampStatus.frame = CGRect(x: width * 0.09, y: width * 0.80, width: width * 0.80, height: width * 0.17)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        [lamp, leave, arrive].contains { $0.frame.contains(point) }
    }

    private func setLamp(_ on: Bool) {
        guard isOn != on else { return }
        isOn = on
        lamp.accessibilityValue = on ? "On" : "Off"
        lampChanged?(on)
        UISelectionFeedbackGenerator().selectionChanged()
        UIView.animate(withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.23,
                       delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.lampFill.alpha = on ? 1 : 0
        }
    }
}

@MainActor
final class StocksChart: UIControl {
    // Normalized samples traced from Apple's two AAPL chart captures.
    static let compact: [CGFloat] = [
        0.323, 0.323, 0.477, 0.554, 0.585, 0.554, 0.385, 0.292, 0.262, 0.169,
        0.431, 0.508, 0.369, 0.523, 0.708, 0.769, 0.769, 0.662, 0.585, 0.569,
        0.523, 0.446, 0.308, 0.246, 0.215, 0.231, 0.277, 0.277, 0.262, 0.246,
        0.246, 0.277, 0.277, 0.231, 0.231, 0.246, 0.246, 0.231, 0.262, 0.292,
        0.323, 0.338, 0.354, 0.369, 0.369, 0.246, 0.523, 0.646, 0.692, 0.738,
        0.723, 0.631, 0.692, 0.785, 0.923, 0.954, 0.969, 0.938, 0.938, 1, 1
    ]
    static let series: [CGFloat] = [
        0.168, 0.141, 0.137, 0.034, 0.107, 0.103, 0.046, 0.084, 0.183, 0.252,
        0.313, 0.290, 0.347, 0.340, 0.332, 0.344, 0.302, 0.374, 0.321, 0.344,
        0.244, 0.282, 0.313, 0.336, 0.366, 0.321, 0.286, 0.271, 0.622, 0.710,
        0.676, 0.687, 0.836, 0.859, 0.901, 0.985, 0.912, 0.847, 0.740, 0.752,
        0.817, 0.771, 0.771, 0.660, 0.756, 0.844, 0.908, 0.908, 0.901, 0.840,
        0.844, 0.832, 0.706, 0.725, 0.718, 0.840, 0.836, 0.756, 0.851, 0.782, 0.782
    ]

    static func plotFrame(in bounds: CGRect) -> CGRect {
        scaled(CGRect(x: 23.0 / 536, y: 496.0 / 1162, width: 441.0 / 536, height: 262.0 / 1162), in: bounds)
    }

    private let cursor = UIView()
    private let dot = UIView()
    private let price = UILabel()
    private var selection: Int?

    init() {
        super.init(frame: .zero)
        isAccessibilityElement = true
        accessibilityLabel = "AAPL sample price chart"
        accessibilityIdentifier = "stocks-chart"
        accessibilityTraits = .adjustable
        accessibilityValue = "Sample data"
        cursor.backgroundColor = UIColor.white.withAlphaComponent(0.48)
        dot.backgroundColor = .systemGreen
        dot.layer.cornerRadius = 4
        dot.layer.borderColor = UIColor.white.cgColor
        dot.layer.borderWidth = 1.5
        price.backgroundColor = UIColor(white: 0.14, alpha: 0.98)
        price.textColor = .white
        price.textAlignment = .center
        price.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        price.layer.cornerRadius = 12
        price.clipsToBounds = true
        for marker in [cursor, dot, price] {
            marker.isUserInteractionEnabled = false
            marker.isHidden = true
            addSubview(marker)
        }
    }

    required init?(coder: NSCoder) { nil }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        scrub(at: touch.location(in: self).x)
        return true
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        scrub(at: touch.location(in: self).x)
        return true
    }

    override func accessibilityIncrement() { show(index: (selection ?? 0) + 1) }
    override func accessibilityDecrement() { show(index: (selection ?? Self.series.count - 1) - 1) }

    func reset() {
        selection = nil
        accessibilityValue = "Sample data"
        for marker in [cursor, dot, price] { marker.isHidden = true }
    }

    private func scrub(at x: CGFloat) {
        guard bounds.width > 0 else { return }
        show(index: Int((unit(x / bounds.width) * CGFloat(Self.series.count - 1)).rounded()))
    }

    private func show(index: Int) {
        let index = min(Self.series.count - 1, max(0, index))
        selection = index
        let x = bounds.width * CGFloat(index) / CGFloat(Self.series.count - 1)
        let value = Self.series[index]
        let y = bounds.height * (1 - value)
        cursor.frame = CGRect(x: x, y: 0, width: 1, height: bounds.height)
        dot.frame = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
        price.frame = CGRect(x: min(max(0, x - 41), max(0, bounds.width - 82)),
                             y: y < 38 ? bounds.height - 32 : 6, width: 82, height: 26)
        price.text = String(format: "$%.2f", 195 + value * 20)
        accessibilityValue = price.text
        for marker in [cursor, dot, price] { marker.isHidden = false }
    }
}

private func scaled(_ rect: CGRect, in bounds: CGRect) -> CGRect {
    CGRect(x: bounds.minX + rect.minX * bounds.width, y: bounds.minY + rect.minY * bounds.height,
           width: rect.width * bounds.width, height: rect.height * bounds.height)
}
