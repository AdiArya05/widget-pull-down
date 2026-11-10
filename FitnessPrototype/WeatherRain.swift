import UIKit

@MainActor
final class WeatherRain {
    let layer = CALayer()
    private let texture = WeatherRain.makeTexture()
    private var size = CGSize.zero
    private var isRunning = false

    func layout(in bounds: CGRect) {
        layer.frame = bounds
        guard size != bounds.size else { return }
        size = bounds.size
        layer.sublayers = nil
        isRunning = false
    }

    func update(intensity: CGFloat) {
        layer.opacity = Float(intensity)
        let shouldRun = intensity > 0 && size.width > 0 && size.height > 0
        guard shouldRun != isRunning else { return }
        isRunning = shouldRun

        if shouldRun {
            for index in 0..<96 {
                addDrop(index)
            }
        } else {
            layer.sublayers = nil
        }
    }

    private func addDrop(_ index: Int) {
        // Spread starting phases so rain is visible as soon as the forecast appears.
        let x = CGFloat((index * 41) % 101) / 101 * (size.width + 42) - 16
        let phase = Double((index * 61 + 17) % 103) / 103
        let depth = CGFloat((index * 29) % 97) / 97
        let length = mix(9, 29, depth)
        let width = mix(0.9, 2.2, depth)
        let speed = mix(215, 545, depth)
        let travel = size.height + length * 2
        let drift = travel * 0.042
        let duration = Double(travel / speed)

        let drop = CALayer()
        drop.bounds = CGRect(x: 0, y: 0, width: width, height: length)
        drop.contents = texture
        drop.opacity = 0
        drop.setAffineTransform(CGAffineTransform(rotationAngle: atan2(drift, travel)))
        layer.addSublayer(drop)

        let fall = CABasicAnimation(keyPath: "position")
        fall.fromValue = CGPoint(x: x, y: -length)
        fall.toValue = CGPoint(x: x - drift, y: size.height + length)
        fall.duration = duration
        fall.timingFunction = CAMediaTimingFunction(name: .linear)

        let fade = CAKeyframeAnimation(keyPath: "opacity")
        let opacity = mix(0.12, 0.49, depth)
        fade.values = [0, opacity, opacity, 0]
        fade.keyTimes = [0, 0.04, 0.95, 1]
        fade.duration = duration

        let loop = CAAnimationGroup()
        loop.animations = [fall, fade]
        loop.duration = duration
        loop.repeatCount = .infinity
        loop.timeOffset = duration * phase
        drop.add(loop, forKey: "rainfall")
    }

    private static func makeTexture() -> CGImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 90), format: format)
        return renderer.image { context in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 6, y: 0))
            path.addQuadCurve(to: CGPoint(x: 11, y: 75), controlPoint: CGPoint(x: 11, y: 54))
            path.addQuadCurve(to: CGPoint(x: 6, y: 90), controlPoint: CGPoint(x: 11, y: 87))
            path.addQuadCurve(to: CGPoint(x: 1, y: 75), controlPoint: CGPoint(x: 1, y: 87))
            path.addQuadCurve(to: CGPoint(x: 6, y: 0), controlPoint: CGPoint(x: 1, y: 54))
            path.close()
            path.addClip()

            let tint = color(200, 224, 246)
            let colors = [tint.withAlphaComponent(0).cgColor, tint.withAlphaComponent(0.45).cgColor,
                          tint.cgColor, tint.withAlphaComponent(0.12).cgColor]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colors as CFArray, locations: [0, 0.56, 0.86, 1]) else { return }
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: 90), options: [])
        }.cgImage
    }
}
