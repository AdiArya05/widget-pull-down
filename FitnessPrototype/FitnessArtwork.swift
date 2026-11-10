import UIKit

/// The widget, the expanding surface and the resize handle share one presented frame.
@MainActor
final class FitnessArtwork {
    private static let reference = CGSize(width: 942, height: 2048)
    private static let widget = CGRect(x: 50, y: 214, width: 842, height: 396)
    private static let widgetRing = CGRect(x: 92, y: 255, width: 313, height: 313)
    private static let summaryRing = CGRect(x: 151, y: 478, width: 640, height: 640)

    private let dim = CALayer()
    private let panel = CALayer()
    private let canvas = CALayer()
    private let plate = CAGradientLayer()
    private let widgetDetails = imageLayer("FitnessHome")
    private let widgetSnapshot = imageLayer("FitnessHome")
    private let header = imageLayer("FitnessSummary")
    private let week = imageLayer("FitnessSummary")
    private let metrics = imageLayer("FitnessSummary")
    private let summary = imageLayer("FitnessSummary")
    private let weatherWidget = imageLayer("WeatherHome")
    private let weatherSummary = imageLayer("WeatherSummary")
    private let rain = WeatherRain()
    private let homeWidget = imageLayer("HomeWidget")
    private let homeRoom = imageLayer("HomeRoom")
    private let homeLampTile = imageLayer("HomeWidget")
    private let stocksWidget = imageLayer("StocksWidget")
    private let stocksDetail = imageLayer("StocksDetail")
    private let stockLine = CAShapeLayer()
    private let stockPlotBackdrop = CALayer()
    private let roomGlow = CAGradientLayer()
    private let compactPrice = CATextLayer()
    private let compactChange = CATextLayer()
    private var lampIsOn = false

    private var faces: [CALayer] { [widgetSnapshot, weatherWidget, homeWidget, stocksWidget] }
    private(set) var kind: WidgetKind = .fitness
    private let ring = MoveRing()
    private let handle = ResizeHandle()

    private var screen = CGRect.zero
    private(set) var widgetFrame = CGRect.zero
    private(set) var backFrame = CGRect.zero

    func attach(to root: CALayer) {
        root.addSublayer(dim)
        root.addSublayer(panel)
        root.addSublayer(handle.layer)

        dim.backgroundColor = UIColor.black.cgColor
        panel.backgroundColor = UIColor.black.cgColor
        panel.masksToBounds = true
        panel.cornerCurve = .continuous
        panel.addSublayer(canvas)
        for layer in [plate, widgetDetails, header, week, metrics, ring.layer, summary,
                      weatherSummary, rain.layer, homeRoom, roomGlow, stocksDetail, stockPlotBackdrop,
                      widgetSnapshot, weatherWidget, homeWidget, stocksWidget, compactPrice, compactChange, homeLampTile, stockLine] {
            canvas.addSublayer(layer)
        }

        plate.colors = [color(30, 30, 31).cgColor, color(13, 13, 13).cgColor]
        for snapshot in faces {
            snapshot.masksToBounds = true
            snapshot.cornerCurve = .continuous
        }
        setCrop(weatherWidget, to: CGRect(x: 48, y: 211, width: 843, height: 398))
        crop(homeWidget, CGRect(x: 1118, y: 427, width: 772, height: 363), size: CGSize(width: 3008, height: 1692))
        crop(homeLampTile, CGRect(x: 1514, y: 617, width: 170, height: 154), size: CGSize(width: 3008, height: 1692))
        homeLampTile.cornerCurve = .continuous
        homeLampTile.masksToBounds = true
        crop(homeRoom, CGRect(x: 42, y: 38, width: 556, height: 1200), size: CGSize(width: 640, height: 1284))
        crop(stocksWidget, CGRect(x: 63, y: 55, width: 318, height: 318), size: CGSize(width: 442, height: 428))
        stockPlotBackdrop.backgroundColor = color(42, 42, 44).cgColor
        stockLine.fillColor = nil
        stockLine.strokeColor = color(92, 220, 96).cgColor
        stockLine.lineCap = .round
        stockLine.lineJoin = .round
        roomGlow.type = .radial
        roomGlow.startPoint = CGPoint(x: 0.28, y: 0.60)
        roomGlow.endPoint = CGPoint(x: 0.92, y: 0.99)
        roomGlow.colors = [UIColor.systemOrange.withAlphaComponent(0.29).cgColor, UIColor.clear.cgColor]
        for label in [compactPrice, compactChange] {
            label.backgroundColor = color(28, 28, 30).cgColor
            label.contentsScale = 3
        }
        compactPrice.alignmentMode = .center
        compactChange.alignmentMode = .right
        setKind(.fitness)
        setCrop(widgetSnapshot, to: Self.widget)
        setCrop(widgetDetails, to: CGRect(x: 445, y: 246, width: 336, height: 327))
        setCrop(header, to: CGRect(x: 0, y: 0, width: 942, height: 270))
        setCrop(week, to: CGRect(x: 0, y: 270, width: 942, height: 167))
        setCrop(metrics, to: CGRect(x: 0, y: 1119, width: 942, height: 929))
    }

    func layout(in bounds: CGRect) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        screen = bounds
        widgetFrame = scale(Self.widget)
        backFrame = scale(CGRect(x: 30, y: 136, width: 121, height: 121))
        dim.frame = bounds
        summary.frame = bounds
        weatherSummary.frame = bounds
        rain.layout(in: bounds)
        homeRoom.frame = bounds
        roomGlow.frame = bounds
        stocksDetail.frame = bounds
        stockPlotBackdrop.frame = StocksChart.plotFrame(in: bounds)
        stockLine.frame = bounds
        canvas.bounds = bounds
        for layer in [widgetSnapshot, widgetDetails, header, week, metrics] {
            placeCrop(layer)
        }
        faces.forEach { $0.cornerRadius = widgetRadius }
        let stockWidth = widgetFrame.height
        compactPrice.string = NSAttributedString(string: "210.23", attributes: [
            .font: UIFont.systemFont(ofSize: stockWidth * 0.22, weight: .light), .foregroundColor: UIColor.white
        ])
        compactChange.string = NSAttributedString(string: "+11.98", attributes: [
            .font: UIFont.systemFont(ofSize: stockWidth * 0.068, weight: .medium), .foregroundColor: UIColor.white
        ])
        CATransaction.commit()
    }

    func setKind(_ kind: WidgetKind) {
        self.kind = kind
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let weather = kind == .weather
        for layer in [widgetDetails, header, week, metrics, ring.layer, summary] {
            layer.isHidden = kind != .fitness
        }
        weatherSummary.isHidden = !weather
        homeRoom.isHidden = kind != .home
        roomGlow.isHidden = kind != .home
        stocksDetail.isHidden = kind != .stocks
        stockLine.isHidden = kind != .stocks
        stockPlotBackdrop.isHidden = kind != .stocks
        homeLampTile.isHidden = kind != .home
        panel.backgroundColor = weather ? color(66, 80, 97).cgColor : UIColor.black.cgColor
        CATransaction.commit()
    }

    func panelFrame(at progress: CGFloat) -> CGRect {
        let spread = progress + 0.30 * progress * (1 - progress)
        let left = mix(widgetFrame.minX, screen.minX, spread)
        let top = mix(widgetFrame.minY, screen.minY, spread)
        let right = mix(widgetFrame.maxX, screen.maxX, spread)
        let bottom = mix(widgetFrame.maxY, screen.maxY, progress)
        return CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    func render(progress: CGFloat, recoil: CGFloat, blend: [CGFloat], rainEnabled: Bool) {
        guard !screen.isEmpty else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let fullWidget = scale(Self.widget)
        widgetFrame = fullWidget
        widgetFrame.size.width = mix(fullWidget.width, fullWidget.height, blend[WidgetKind.stocks.order])
        let frame = panelFrame(at: progress)
        panel.frame = frame
        panel.cornerRadius = widgetRadius * (1 - ramp(progress, from: 0.75, to: 1))
        let grip = handleCorner(at: progress)
        handle.place(at: grip, scale: screen.width / Self.reference.width)
        dim.opacity = Float(0.32 * progress)
        plate.frame = frame
        plate.opacity = Float(1 - ramp(progress, from: 0.06, to: 0.37))
        let weatherBlend = blend[WidgetKind.weather.order]
        plate.colors = [
            color(mix(30, 103, weatherBlend), mix(30, 114, weatherBlend), mix(31, 129, weatherBlend)).cgColor,
            color(mix(13, 71, weatherBlend), mix(13, 84, weatherBlend), mix(13, 100, weatherBlend)).cgColor
        ]
        let center = blend.enumerated().reduce(CGFloat.zero) { $0 + CGFloat($1.offset) * $1.element }
        let previewEnds: [CGFloat] = [0.11, 0.25, 0.31, 0.24]
        var accumulatedWeight: CGFloat = 0
        for (index, face) in faces.enumerated() {
            let offset = min(1, max(-1, CGFloat(index) - center)) * 16
            var faceFrame = fullWidget
            if index == WidgetKind.stocks.order { faceFrame.size.width = fullWidget.height }
            face.frame = faceFrame.offsetBy(dx: offset * (1 - ramp(progress, from: 0, to: 0.24)), dy: 0)
            accumulatedWeight += blend[index]
            let opacity = accumulatedWeight > 0 ? blend[index] / accumulatedWeight : 0
            face.opacity = Float(opacity * (1 - ramp(progress, from: 0.02, to: previewEnds[index])))
        }
        let stockFace = stocksWidget.frame
        compactPrice.frame = CGRect(x: stockFace.minX + stockFace.width * 0.075,
                                    y: stockFace.minY + stockFace.height * 0.69,
                                    width: stockFace.width * 0.85, height: stockFace.height * 0.235)
        compactChange.frame = CGRect(x: stockFace.minX + stockFace.width * 0.64,
                                     y: stockFace.minY + stockFace.height * 0.088,
                                     width: stockFace.width * 0.253, height: stockFace.height * 0.09)
        compactPrice.opacity = stocksWidget.opacity
        compactChange.opacity = stocksWidget.opacity

        let rainIntensity = rainEnabled && kind == .weather ? ramp(progress, from: 0.18, to: 0.66) : 0
        rain.update(intensity: rainIntensity)

        switch kind {
        case .weather:
            let reveal = ramp(progress, from: 0.12, to: 0.56)
            weatherSummary.opacity = Float(reveal)
            weatherSummary.setAffineTransform(CGAffineTransform(translationX: 0, y: 10 * (1 - reveal)))
        case .home:
            homeRoom.opacity = Float(ramp(progress, from: 0.16, to: 0.66))
            roomGlow.opacity = lampIsOn ? homeRoom.opacity : 0
            let tileStart = CGRect(x: widgetFrame.minX + widgetFrame.width * 0.51,
                                   y: widgetFrame.minY + widgetFrame.height * 0.52,
                                   width: widgetFrame.width * 0.22, height: widgetFrame.height * 0.424)
            let amount = ramp(progress, from: 0.11, to: 0.78)
            homeLampTile.frame = mix(tileStart, RoomControls.lampFrame(in: screen), amount)
            homeLampTile.cornerRadius = homeLampTile.frame.width * 0.15
            homeLampTile.opacity = Float(ramp(progress, from: 0.12, to: 0.27)
                                         * (1 - ramp(progress, from: 0.62, to: 0.87)))
        case .stocks:
            stocksDetail.opacity = Float(ramp(progress, from: 0.19, to: 0.78))
            stockPlotBackdrop.opacity = Float(ramp(progress, from: 0.13, to: 0.27)
                                               * (1 - ramp(progress, from: 0.76, to: 0.91)))
            renderStockLine(progress: progress)
        case .fitness:
            widgetDetails.opacity = Float(1 - ramp(progress, from: 0.08, to: 0.31))
            header.opacity = Float(ramp(progress, from: 0.21, to: 0.60))
            week.opacity = Float(ramp(progress, from: 0.65, to: 0.82))
            metrics.opacity = Float(ramp(progress, from: 0.49, to: 0.84))
            ring.place(
                in: mix(scale(Self.widgetRing), scale(Self.summaryRing), ramp(progress, from: 0.055, to: 0.93)),
                progress: progress
            )
            summary.opacity = Float(ramp(progress, from: 0.87, to: 1))
        }

        // Keep the screen fixed while the panel reveals it. Release adds a small, anchored settle.
        canvas.position = CGPoint(
            x: screen.midX - frame.minX,
            y: screen.midY - frame.minY + screen.height * recoil * 0.5
        )
        canvas.setAffineTransform(CGAffineTransform(scaleX: 1, y: 1 + recoil))

        CATransaction.commit()
    }

    func setLamp(_ on: Bool) {
        lampIsOn = on
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.28)
        roomGlow.opacity = on ? homeRoom.opacity : 0
        CATransaction.commit()
    }

    private func renderStockLine(progress: CGFloat) {
        let amount = ramp(progress, from: 0.08, to: 0.76)
        let start = CGRect(x: widgetFrame.minX + widgetFrame.width * 0.093,
                           y: widgetFrame.minY + widgetFrame.height * 0.37,
                           width: widgetFrame.width * 0.80, height: widgetFrame.height * 0.20)
        let end = StocksChart.plotFrame(in: screen)
        let plot = mix(start, end, amount)
        let path = UIBezierPath()
        for index in StocksChart.compact.indices {
            let x = CGFloat(index) / CGFloat(StocksChart.compact.count - 1)
            let value = mix(StocksChart.compact[index], StocksChart.series[index], amount)
            let point = CGPoint(x: plot.minX + plot.width * x, y: plot.maxY - plot.height * value)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        stockLine.path = path.cgPath
        stockLine.lineWidth = mix(1.6, 2, amount)
        stockLine.opacity = Float(ramp(progress, from: 0.09, to: 0.31)
                                  * (1 - ramp(progress, from: 0.76, to: 0.91)))
    }

    private func crop(_ layer: CALayer, _ rect: CGRect, size: CGSize) {
        layer.contentsRect = CGRect(x: rect.minX / size.width, y: rect.minY / size.height,
                                    width: rect.width / size.width, height: rect.height / size.height)
    }

    func handleHitFrame(at progress: CGFloat) -> CGRect {
        let corner = handleCorner(at: progress)
        return CGRect(x: corner.x - 51, y: corner.y - 52, width: 64, height: 63)
    }

    private func handleCorner(at progress: CGFloat) -> CGPoint {
        let frame = panelFrame(at: progress)
        // As the panel meets the screen, keep the hook inside the display's rounded corner.
        let inset = ramp(progress, from: 0.32, to: 1)
        return CGPoint(x: frame.maxX - 15 * inset, y: frame.maxY - 23 * inset)
    }

    private var widgetRadius: CGFloat { 69 * screen.width / Self.reference.width }

    private func scale(_ rect: CGRect) -> CGRect {
        let sx = screen.width / Self.reference.width
        let sy = screen.height / Self.reference.height
        return CGRect(x: rect.minX * sx, y: rect.minY * sy, width: rect.width * sx, height: rect.height * sy)
    }

    private func setCrop(_ layer: CALayer, to rect: CGRect) {
        layer.contentsRect = CGRect(
            x: rect.minX / Self.reference.width, y: rect.minY / Self.reference.height,
            width: rect.width / Self.reference.width, height: rect.height / Self.reference.height
        )
    }

    private func placeCrop(_ layer: CALayer) {
        let crop = layer.contentsRect
        layer.frame = CGRect(
            x: crop.minX * screen.width, y: crop.minY * screen.height,
            width: crop.width * screen.width, height: crop.height * screen.height
        )
    }
}

private final class ResizeHandle {
    let layer = CALayer()

    init() {
        layer.bounds = CGRect(x: 0, y: 0, width: 72, height: 72)
        let hook = UIBezierPath()
        hook.move(to: CGPoint(x: 15, y: 57))
        hook.addCurve(to: CGPoint(x: 57, y: 15),
                      controlPoint1: CGPoint(x: 39, y: 57),
                      controlPoint2: CGPoint(x: 57, y: 39))

        let edge = CAShapeLayer()
        edge.path = hook.cgPath
        edge.fillColor = nil
        edge.lineCap = .round
        edge.lineWidth = 30
        edge.strokeColor = color(190, 204, 230).withAlphaComponent(0.32).cgColor
        edge.frame = layer.bounds
        layer.addSublayer(edge)

        let glass = CAGradientLayer()
        glass.frame = layer.bounds
        glass.startPoint = CGPoint(x: 0.18, y: 0.13)
        glass.endPoint = CGPoint(x: 0.80, y: 0.91)
        glass.colors = [
            color(197, 207, 223).withAlphaComponent(0.50).cgColor,
            color(92, 105, 132).withAlphaComponent(0.62).cgColor,
            color(175, 192, 222).withAlphaComponent(0.47).cgColor
        ]
        glass.locations = [0, 0.54, 1]
        let mask = CAShapeLayer()
        mask.frame = layer.bounds
        mask.path = hook.cgPath
        mask.fillColor = nil
        mask.strokeColor = UIColor.black.cgColor
        mask.lineCap = .round
        mask.lineWidth = 26
        glass.mask = mask
        layer.addSublayer(glass)
    }

    func place(at corner: CGPoint, scale: CGFloat) {
        layer.position = CGPoint(x: corner.x - 21 * scale, y: corner.y - 21 * scale)
        layer.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
    }
}

private func imageLayer(_ name: String) -> CALayer {
    let layer = CALayer()
    layer.contents = UIImage(named: name)?.cgImage
    layer.contentsGravity = .resize
    return layer
}

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
    UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
}

func unit(_ value: CGFloat) -> CGFloat { min(1, max(0, value)) }

func ramp(_ value: CGFloat, from start: CGFloat, to end: CGFloat) -> CGFloat {
    let t = unit((value - start) / (end - start))
    return t * t * (3 - 2 * t)
}

func mix(_ start: CGFloat, _ end: CGFloat, _ amount: CGFloat) -> CGFloat {
    start + (end - start) * amount
}

private func mix(_ start: CGRect, _ end: CGRect, _ amount: CGFloat) -> CGRect {
    CGRect(
        x: mix(start.minX, end.minX, amount), y: mix(start.minY, end.minY, amount),
        width: mix(start.width, end.width, amount), height: mix(start.height, end.height, amount)
    )
}
