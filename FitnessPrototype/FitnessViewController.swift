import SwiftUI
import UIKit

final class FitnessViewController: UIViewController, UIGestureRecognizerDelegate {
    private let artwork = FitnessArtwork()
    private let back = UIButton(type: .custom)
    private let collapse = UIButton(type: .custom)
    private lazy var home = UIHostingController(rootView: WidgetHome { [weak self] kind in
        self?.select(kind) ?? false
    })
    private var widgetElement: WidgetAccessibilityElement?
    private let feedback = UIImpactFeedbackGenerator(style: .soft)

    private var progress: CGFloat = 0
    private var recoil: CGFloat = 0
    private var isOpen = false
    private var dragOrigin: CGFloat = 0
    private var dragDistance: CGFloat = 1
    private var displayLink: CADisplayLink?
    private var spring: SettleSpring?
    private var weatherBlend: CGFloat = 0
    private var widgetSwitch: WidgetSwitch?
    private var isSceneActive = false

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        addChild(home)
        home.view.frame = view.bounds
        home.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(home.view)
        home.didMove(toParent: self)
        artwork.attach(to: view.layer)

        // Direct touch is reserved for the drag. VoiceOver can activate the widget as a button.
        let widgetElement = WidgetAccessibilityElement(accessibilityContainer: view as UIView)
        widgetElement.accessibilityTraits = .button
        widgetElement.activate = { [weak self] in self?.settle(open: true, velocity: 0) }
        self.widgetElement = widgetElement

        back.accessibilityLabel = "Back to Home"
        back.accessibilityIdentifier = "fitness-back"
        back.addAction(UIAction { [weak self] _ in self?.settle(open: false, velocity: 0) }, for: .touchUpInside)
        view.addSubview(back)

        collapse.accessibilityLabel = "Collapse widget"
        collapse.accessibilityHint = "Swipe up from the bottom-right hook to return to the widget."
        collapse.accessibilityIdentifier = "widget-collapse"
        collapse.addAction(UIAction { [weak self] _ in self?.settle(open: false, velocity: 0) }, for: .touchUpInside)
        view.addSubview(collapse)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(drag(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        view.addGestureRecognizer(pan)
        updateControls()
        NotificationCenter.default.addObserver(self, selector: #selector(render),
                                               name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
    }

    func setSceneActive(_ active: Bool) {
        isSceneActive = active
        if isViewLoaded { render() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        artwork.layout(in: view.bounds)
        widgetElement?.accessibilityFrameInContainerSpace = artwork.widgetFrame
        back.frame = artwork.backFrame
        render()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: view)
        if artwork.handleHitFrame(at: progress).contains(point) { return true }
        guard !isOpen else { return false }
        let frame = artwork.panelFrame(at: progress)
        let insideLowerEdge = ((frame.maxY - 39)...(frame.maxY + 20)).contains(point.y)
        let nearCorner = min(abs(point.x - frame.minX), abs(point.x - frame.maxX)) <= 67
        return insideLowerEdge && nearCorner
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let velocity = pan.velocity(in: view)
        let verticalVelocity = isOpen ? -velocity.y : velocity.y
        return verticalVelocity > abs(velocity.x) * 0.9
    }

    @objc private func drag(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            spring = nil
            stopDisplayLinkIfIdle()
            dragOrigin = progress
            let touchY = pan.location(in: view).y
            let endY = isOpen ? artwork.widgetFrame.maxY : view.bounds.maxY
            let travel = isOpen ? dragOrigin : 1 - dragOrigin
            dragDistance = max(1, abs(endY - touchY)) / max(0.02, travel)
            pan.setTranslation(.zero, in: view)
            recoil = 0
            feedback.prepare()
        case .changed:
            progress = unit(dragOrigin + pan.translation(in: view).y / dragDistance)
            render()
        case .ended:
            progress = unit(dragOrigin + pan.translation(in: view).y / dragDistance)
            let velocity = pan.velocity(in: view).y / dragDistance
            let projected = progress + min(0.20, max(-0.18, velocity * 0.12))
            let shouldOpen = progress >= 0.90 || (progress > 0.10 && projected >= 0.50)
            if shouldOpen != isOpen { feedback.impactOccurred(intensity: 0.55) }
            settle(open: shouldOpen, velocity: velocity)
        case .cancelled, .failed:
            settle(open: isOpen, velocity: 0)
        default:
            break
        }
    }

    private func settle(open: Bool, velocity: CGFloat) {
        let didOpen = open && !isOpen
        isOpen = open
        updateControls()
        let target: CGFloat = open ? 1 : 0
        let remaining = target - progress
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        let response: CGFloat = reduceMotion ? 34 : 19
        let direction: CGFloat = remaining < 0 ? -1 : 1
        // Preserve a flick's velocity while keeping the panel itself inside the screen.
        let speed = min(abs(remaining) * response, max(0, direction * velocity))
        spring = SettleSpring(
            start: progress, target: target, velocity: reduceMotion ? 0 : direction * speed,
            time: CACurrentMediaTime(), response: response, initialRecoil: recoil,
            bounces: didOpen && !reduceMotion
        )
        render()
        startDisplayLink()
    }

    private func startDisplayLink() {
        guard displayLink == nil else { return }
        let tick = DisplayTick(owner: self)
        let link = CADisplayLink(target: tick, selector: #selector(DisplayTick.step(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    fileprivate func advance(to timestamp: CFTimeInterval) {
        if let switchAnimation = widgetSwitch {
            let fraction = unit(CGFloat((timestamp - switchAnimation.time) / WidgetSwitch.duration))
            weatherBlend = mix(switchAnimation.start, switchAnimation.target, ramp(fraction, from: 0, to: 1))
            if fraction == 1 { widgetSwitch = nil }
        }

        if let spring {
            let elapsed = CGFloat(max(0, timestamp - spring.time))
            progress = unit(spring.position(at: elapsed))
            recoil = spring.recoil(at: elapsed, progress: progress)

            let hasSettled = abs(progress - spring.target) < 0.0005 && abs(recoil) < 0.0001
            if elapsed >= 0.56 || (hasSettled && (!spring.bounces || elapsed >= 0.34)) {
                progress = spring.target
                recoil = 0
                self.spring = nil
                if UIAccessibility.isVoiceOverRunning {
                    let focus: Any? = isOpen ? collapse : widgetElement
                    UIAccessibility.post(notification: .screenChanged, argument: focus)
                }
            }
        }
        render()
        stopDisplayLinkIfIdle()
    }

    private func stopDisplayLinkIfIdle() {
        guard spring == nil, widgetSwitch == nil else { return }
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func render() {
        artwork.render(progress: progress, recoil: recoil, weatherBlend: weatherBlend,
                       rainEnabled: isSceneActive && !UIAccessibility.isReduceMotionEnabled)
        collapse.frame = artwork.handleHitFrame(at: progress)
    }

    private func select(_ kind: WidgetKind) -> Bool {
        guard !isOpen, progress == 0 else { return false }
        guard artwork.kind != kind else { return true }
        artwork.setKind(kind)
        let target: CGFloat = kind == .weather ? 1 : 0
        if UIAccessibility.isReduceMotionEnabled {
            widgetSwitch = nil
            weatherBlend = target
            stopDisplayLinkIfIdle()
        } else {
            widgetSwitch = WidgetSwitch(start: weatherBlend, target: target, time: CACurrentMediaTime())
            startDisplayLink()
        }
        render()
        updateControls()
        return true
    }

    private func updateControls() {
        back.isHidden = !isOpen || artwork.kind != .fitness
        collapse.isHidden = !isOpen
        home.view.isUserInteractionEnabled = !isOpen

        if isOpen {
            view.accessibilityElements = back.isHidden ? [collapse] : [back, collapse]
        } else if let widgetElement {
            let kind = artwork.kind
            widgetElement.accessibilityLabel = "\(kind.rawValue) widget"
            widgetElement.accessibilityHint = "Open \(kind.rawValue), or drag down from either lower corner."
            widgetElement.accessibilityIdentifier = "\(kind.identifier)-widget"
            view.accessibilityElements = [widgetElement, home.view as UIView]
        }
    }
}

struct WidgetSwitch {
    static let duration: TimeInterval = 0.44

    let start: CGFloat
    let target: CGFloat
    let time: CFTimeInterval
}

private struct SettleSpring {
    let start: CGFloat
    let target: CGFloat
    let velocity: CGFloat
    let time: CFTimeInterval
    let response: CGFloat
    let initialRecoil: CGFloat
    let bounces: Bool

    func position(at elapsed: CGFloat) -> CGFloat {
        let displacement = start - target
        return target + (displacement + (velocity + response * displacement) * elapsed) * exp(-response * elapsed)
    }

    func recoil(at elapsed: CGFloat, progress: CGFloat) -> CGFloat {
        let phase = unit(elapsed / 0.34)
        let decay = 1 - phase
        guard bounces else { return initialRecoil * decay }
        // Keep a shallow elastic response even when the finger already reached the endpoint.
        let pulse = 0.014 * sin(2 * .pi * phase) * sin(.pi * phase) * decay
        return initialRecoil * decay + pulse * ramp(progress, from: 0.88, to: 1)
    }
}

private final class DisplayTick: NSObject {
    weak var owner: FitnessViewController?

    init(owner: FitnessViewController) { self.owner = owner }

    @MainActor @objc func step(_ link: CADisplayLink) {
        guard let owner else { link.invalidate(); return }
        owner.advance(to: link.targetTimestamp)
    }
}

private final class WidgetAccessibilityElement: UIAccessibilityElement {
    var activate: (() -> Void)?

    override func accessibilityActivate() -> Bool {
        activate?()
        return activate != nil
    }
}
