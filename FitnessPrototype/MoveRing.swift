import UIKit

@MainActor
final class MoveRing {
    let layer = CALayer()
    private let track = CAShapeLayer()
    private let widgetTrack = CAShapeLayer()
    private let move = CAShapeLayer()
    private let diameter: CGFloat = 640

    init() {
        layer.bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        let arrow = CAShapeLayer()
        for shape in [track, widgetTrack, move, arrow] {
            shape.frame = layer.bounds
            shape.fillColor = nil
            layer.addSublayer(shape)
        }

        track.path = UIBezierPath(ovalIn: CGRect(x: 64, y: 64, width: 512, height: 512)).cgPath
        track.strokeColor = color(38, 3, 12).cgColor
        track.lineWidth = 128
        widgetTrack.path = track.path
        widgetTrack.strokeColor = color(66, 19, 31).cgColor
        widgetTrack.lineWidth = 128

        move.path = UIBezierPath(arcCenter: CGPoint(x: 320, y: 320), radius: 256,
                                startAngle: -.pi / 2, endAngle: 3 * .pi / 2, clockwise: true).cgPath
        move.lineWidth = 128
        move.lineCap = .round
        move.strokeColor = color(249, 17, 79).cgColor

        let arrowPath = UIBezierPath()
        arrowPath.move(to: CGPoint(x: 294, y: 64))
        arrowPath.addLine(to: CGPoint(x: 347, y: 64))
        arrowPath.move(to: CGPoint(x: 319, y: 32))
        arrowPath.addLine(to: CGPoint(x: 347, y: 64))
        arrowPath.addLine(to: CGPoint(x: 319, y: 96))
        arrow.path = arrowPath.cgPath
        arrow.lineWidth = 9
        arrow.lineCap = .round
        arrow.lineJoin = .round
        arrow.strokeColor = UIColor.black.cgColor
    }

    func place(in frame: CGRect, progress: CGFloat) {
        layer.position = CGPoint(x: frame.midX, y: frame.midY)
        layer.setAffineTransform(CGAffineTransform(scaleX: frame.width / diameter, y: frame.height / diameter))
        widgetTrack.opacity = Float(1 - ramp(progress, from: 0, to: 0.68))
        move.strokeEnd = mix(0.125, 0.097, progress)
    }
}
