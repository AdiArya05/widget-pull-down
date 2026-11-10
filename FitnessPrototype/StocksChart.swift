import UIKit

@MainActor
final class StocksChart: UIControl {
    // Equal time samples traced from the supplied AAPL captures.
    static let compact: [CGFloat] = [
        0.051, 0.145, 0.274, 0.419, 0.521, 0.496, 0.462, 0.393, 0.342, 0.282,
        0.239, 0.299, 0.359, 0.419, 0.453, 0.479, 0.513, 0.538, 0.573, 0.615,
        0.650, 0.684, 0.726, 0.718, 0.709, 0.684, 0.692, 0.692, 0.701, 0.692,
        0.684, 0.667, 0.650, 0.624, 0.581, 0.564, 0.547, 0.530, 0.513, 0.504,
        0.504, 0.487, 0.470, 0.453, 0.470, 0.530, 0.573, 0.598, 0.607, 0.607,
        0.598, 0.581, 0.564, 0.556, 0.538, 0.521, 0.504, 0.470, 0.444, 0.427,
        0.444, 0.453, 0.453, 0.444, 0.436, 0.436, 0.444, 0.453, 0.462, 0.444,
        0.436, 0.419, 0.419, 0.419, 0.427, 0.453, 0.479, 0.513, 0.547, 0.581,
        0.607, 0.624, 0.632, 0.658, 0.701, 0.752, 0.786, 0.829, 0.846, 0.863,
        0.838, 0.803, 0.761, 0.795, 0.838, 0.897, 0.880, 0.846, 0.803, 0.795,
        0.795, 0.803, 0.803, 0.812, 0.812, 0.803, 0.778, 0.744, 0.726, 0.718,
        0.718, 0.709, 0.701, 0.684, 0.701, 0.744, 0.803, 0.821, 0.769, 0.709,
        0.675,
    ]
    static let series: [CGFloat] = [
        0.476, 0.608, 0.630, 0.753, 0.750, 0.712, 0.679, 0.656, 0.644, 0.636,
        0.580, 0.637, 0.661, 0.622, 0.677, 0.693, 0.753, 0.758, 0.793, 0.808,
        0.801, 0.824, 0.846, 0.884, 0.867, 0.836, 0.846, 0.857, 0.858, 0.826,
        0.812, 0.841, 0.834, 0.831, 0.838, 0.791, 0.756, 0.760, 0.770, 0.758,
        0.734, 0.734, 0.741, 0.720, 0.739, 0.791, 0.808, 0.794, 0.774, 0.753,
        0.769, 0.789, 0.786, 0.796, 0.775, 0.753, 0.750, 0.741, 0.734, 0.694,
        0.684, 0.674, 0.694, 0.698, 0.701, 0.703, 0.708, 0.706, 0.710, 0.713,
        0.694, 0.677, 0.679, 0.677, 0.687, 0.694, 0.705, 0.736, 0.760, 0.782,
        0.794, 0.820, 0.832, 0.824, 0.870, 0.891, 0.903, 0.927, 0.946, 0.943,
        0.919, 0.907, 0.886, 0.896, 0.881, 0.946, 0.957, 0.888, 0.891, 0.879,
        0.896, 0.900, 0.903, 0.898, 0.912, 0.921, 0.929, 0.905, 0.881, 0.879,
        0.862, 0.836, 0.832, 0.850, 0.839, 0.846, 0.870, 0.891, 0.889, 0.857,
        0.836,
    ]

    static func plotFrame(in bounds: CGRect) -> CGRect {
        scaled(CGRect(x: 37.0 / 942, y: 829.0 / 2048, width: 784.0 / 942, height: 452.0 / 2048), in: bounds)
    }

    static func sparklineFrame(in widget: CGRect) -> CGRect {
        scaled(CGRect(x: 42.0 / 397, y: 117.0 / 396, width: 314.0 / 397, height: 91.0 / 396), in: widget)
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
        let closingSample = Self.series[Self.series.count - 1]
        price.text = String(format: "$%.2f", 350.69 + (value - closingSample) * 10)
        accessibilityValue = price.text
        for marker in [cursor, dot, price] { marker.isHidden = false }
    }
}

private func scaled(_ rect: CGRect, in bounds: CGRect) -> CGRect {
    CGRect(x: bounds.minX + rect.minX * bounds.width, y: bounds.minY + rect.minY * bounds.height,
           width: rect.width * bounds.width, height: rect.height * bounds.height)
}
