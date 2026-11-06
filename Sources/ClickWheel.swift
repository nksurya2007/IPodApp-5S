import UIKit

final class ClickWheel: UIView {
    var onStep: ((Int) -> Void)?
    var onCenter, onMenu, onPlay, onNext, onPrev: (() -> Void)?

    private var lastAngle: CGFloat = 0
    private var acc: CGFloat = 0
    private var moved = false
    private var start = CGPoint.zero
    private let centerBtn = UIView()
    private var labels: [UILabel] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0.90, alpha: 1)
        centerBtn.backgroundColor = UIColor(white: 0.98, alpha: 1)
        centerBtn.isUserInteractionEnabled = false
        addSubview(centerBtn)
        for t in ["MENU", "\u{25B6}\u{FE0E}\u{2758}\u{2758}", "\u{25C0}\u{25C0}", "\u{25B6}\u{25B6}"] {
            let l = UILabel()
            l.text = t
            l.font = UIFont.boldSystemFont(ofSize: 13)
            l.textColor = UIColor(white: 0.55, alpha: 1)
            l.sizeToFit()
            l.isUserInteractionEnabled = false
            addSubview(l)
            labels.append(l)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

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
        centerBtn.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
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
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self) else { return }
        let a = angle(p)
        var d = a - lastAngle
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        lastAngle = a
        acc += d
        if hypot(p.x - start.x, p.y - start.y) > 12 { moved = true }
        guard moved else { return }
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
