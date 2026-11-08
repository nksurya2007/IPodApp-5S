import UIKit

struct WheelStyle {
    let name: String
    let ring: UIColor
    let center: UIColor
    let label: UIColor
    let border: UIColor

    static let all: [WheelStyle] = [
        WheelStyle(name: "White",
                   ring: UIColor(white: 0.90, alpha: 1),
                   center: UIColor(white: 0.98, alpha: 1),
                   label: UIColor(white: 0.55, alpha: 1),
                   border: UIColor(white: 0.80, alpha: 1)),
        WheelStyle(name: "Black",
                   ring: UIColor(white: 0.12, alpha: 1),
                   center: UIColor(white: 0.20, alpha: 1),
                   label: UIColor(white: 0.85, alpha: 1),
                   border: UIColor(white: 0.32, alpha: 1)),
        WheelStyle(name: "Silver",
                   ring: UIColor(red: 0.74, green: 0.76, blue: 0.79, alpha: 1),
                   center: UIColor(red: 0.84, green: 0.86, blue: 0.89, alpha: 1),
                   label: UIColor(white: 0.30, alpha: 1),
                   border: UIColor(red: 0.60, green: 0.62, blue: 0.66, alpha: 1)),
        WheelStyle(name: "Red",
                   ring: UIColor(red: 0.80, green: 0.12, blue: 0.16, alpha: 1),
                   center: UIColor(red: 0.90, green: 0.25, blue: 0.28, alpha: 1),
                   label: UIColor(white: 1.0, alpha: 0.9),
                   border: UIColor(red: 0.62, green: 0.08, blue: 0.12, alpha: 1)),
        WheelStyle(name: "Gold",
                   ring: UIColor(red: 0.85, green: 0.72, blue: 0.35, alpha: 1),
                   center: UIColor(red: 0.93, green: 0.83, blue: 0.52, alpha: 1),
                   label: UIColor(red: 0.35, green: 0.25, blue: 0.05, alpha: 1),
                   border: UIColor(red: 0.65, green: 0.52, blue: 0.20, alpha: 1)),
        WheelStyle(name: "Blue",
                   ring: UIColor(red: 0.25, green: 0.45, blue: 0.80, alpha: 1),
                   center: UIColor(red: 0.40, green: 0.60, blue: 0.92, alpha: 1),
                   label: UIColor(white: 1.0, alpha: 0.9),
                   border: UIColor(red: 0.15, green: 0.32, blue: 0.62, alpha: 1)),
        WheelStyle(name: "Pink",
                   ring: UIColor(red: 0.93, green: 0.55, blue: 0.70, alpha: 1),
                   center: UIColor(red: 0.97, green: 0.72, blue: 0.82, alpha: 1),
                   label: UIColor(red: 0.45, green: 0.10, blue: 0.25, alpha: 1),
                   border: UIColor(red: 0.78, green: 0.38, blue: 0.55, alpha: 1)),
        WheelStyle(name: "Green",
                   ring: UIColor(red: 0.25, green: 0.62, blue: 0.35, alpha: 1),
                   center: UIColor(red: 0.42, green: 0.78, blue: 0.50, alpha: 1),
                   label: UIColor(white: 1.0, alpha: 0.9),
                   border: UIColor(red: 0.15, green: 0.45, blue: 0.25, alpha: 1))
    ]
}

final class ClickWheel: UIView {
    var onStep: ((Int) -> Void)?
    var onRotate: ((CGFloat) -> Void)?   // raw rotation in degrees (used by the game)
    var onTouch: (() -> Void)?           // any touch (wakes the backlight)
    var onCenter, onMenu, onPlay, onNext, onPrev: (() -> Void)?

    var style: WheelStyle = WheelStyle.all[0] {
        didSet { applyStyle() }
    }

    private var lastAngle: CGFloat = 0
    private var acc: CGFloat = 0
    private var moved = false
    private var start = CGPoint.zero
    private let centerBtn = UIView()
    private var labels: [UILabel] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        centerBtn.isUserInteractionEnabled = false
        addSubview(centerBtn)
        for t in ["MENU", "\u{25B6}\u{FE0E}\u{2758}\u{2758}", "\u{25C0}\u{25C0}", "\u{25B6}\u{25B6}"] {
            let l = UILabel()
            l.text = t
            l.font = UIFont.boldSystemFont(ofSize: 13)
            l.sizeToFit()
            l.isUserInteractionEnabled = false
            addSubview(l)
            labels.append(l)
        }
        applyStyle()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func applyStyle() {
        backgroundColor = style.ring
        centerBtn.backgroundColor = style.center
        centerBtn.layer.borderColor = style.border.cgColor
        labels.forEach { $0.textColor = style.label }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        layer.cornerRadius = w / 2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
        let c = w * 0.34
        centerBtn.frame = CGRect(x: (w - c) / 2, y: (w - c) / 2, width: c, height: c)
        centerBtn.layer.cornerRadius = c / 2
        centerBtn.layer.borderWidth = 1
        labels[0].center = CGPoint(x: w / 2, y: w * 0.12)
        labels[1].center = CGPoint(x: w / 2, y: w * 0.88)
        labels[2].center = CGPoint(x: w * 0.12 + labels[2].bounds.width / 2, y: w / 2)
        labels[3].center = CGPoint(x: w * 0.88 - labels[3].bounds.width / 2, y: w / 2)
    }

    private func angle(_ p: CGPoint) -> CGFloat {
        return atan2(p.y - bounds.midY, p.x - bounds.midX) * 180 / .pi
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self) else { return }
        lastAngle = angle(p); acc = 0; moved = false; start = p
        onTouch?()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self) else { return }
        onTouch?()
        let a = angle(p)
        var d = a - lastAngle
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        lastAngle = a
        acc += d
        if hypot(p.x - start.x, p.y - start.y) > 12 { moved = true }
        guard moved else { return }
        onRotate?(d)
        while acc >= 24 { onStep?(1); acc -= 24 }
        while acc <= -24 { onStep?(-1); acc += 24 }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !moved, let p = touches.first?.location(in: self) else { return }
        let dx = p.x - bounds.midX, dy = p.y - bounds.midY
        if hypot(dx, dy) < bounds.width * 0.17 { onCenter?(); return }
        let a = atan2(dy, dx) * 180 / .pi
        if a >= -135 && a < -45 { onMenu?() }
        else if a >= 45 && a < 135 { onPlay?() }
        else if a >= -45 && a < 45 { onNext?() }
        else { onPrev?() }
    }
}
