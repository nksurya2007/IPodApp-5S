import UIKit

/// Simple Breakout game played with the click wheel.
/// Rotate = move paddle, center = launch / pause / restart, MENU = exit.
final class BrickGameView: UIView {
    private enum State { case ready, playing, paused, over, won }
    private var state: State = .ready

    private let paddle = UIView()
    private let ball = UIView()
    private var bricks: [UIView] = []
    private let scoreLabel = UILabel()
    private let msgLabel = UILabel()

    private var link: CADisplayLink?
    private var lastTime: CFTimeInterval = 0
    private var vel = CGPoint.zero
    private var score = 0
    private var lives = 3
    private let ballR: CGFloat = 5
    private let baseSpeed: CGFloat = 210
    private var built = false

    var isRunning: Bool { return state == .playing }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0.05, alpha: 1)
        clipsToBounds = true
        paddle.backgroundColor = .white
        paddle.layer.cornerRadius = 4
        ball.backgroundColor = .white
        ball.layer.cornerRadius = ballR
        scoreLabel.font = UIFont.boldSystemFont(ofSize: 11)
        scoreLabel.textColor = .white
        msgLabel.font = UIFont.boldSystemFont(ofSize: 14)
        msgLabel.textColor = .white
        msgLabel.textAlignment = .center
        msgLabel.numberOfLines = 0
        addSubview(paddle)
        addSubview(ball)
        addSubview(scoreLabel)
        addSubview(msgLabel)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        scoreLabel.frame = CGRect(x: 6, y: 4, width: bounds.width - 12, height: 16)
        msgLabel.frame = CGRect(x: 10, y: bounds.height * 0.52, width: bounds.width - 20, height: 70)
        if !built && bounds.width > 0 {
            built = true
            newGame()
        }
    }

    // MARK: Control
    func start() {
        guard link == nil else { return }
        lastTime = CACurrentMediaTime()
        link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link?.add(to: .main, forMode: .common)
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    func newGame() {
        guard bounds.width > 0 else { return }
        bricks.forEach { $0.removeFromSuperview() }
        bricks.removeAll()
        let cols = 7, rows = 5
        let gap: CGFloat = 3
        let bw = (bounds.width - gap * CGFloat(cols + 1)) / CGFloat(cols)
        let bh: CGFloat = 12
        let colors: [UIColor] = [
            UIColor(red: 0.90, green: 0.25, blue: 0.25, alpha: 1),
            UIColor(red: 0.95, green: 0.55, blue: 0.15, alpha: 1),
            UIColor(red: 0.95, green: 0.85, blue: 0.20, alpha: 1),
            UIColor(red: 0.30, green: 0.75, blue: 0.35, alpha: 1),
            UIColor(red: 0.25, green: 0.55, blue: 0.90, alpha: 1)
        ]
        for r in 0..<rows {
            for c in 0..<cols {
                let b = UIView(frame: CGRect(x: gap + CGFloat(c) * (bw + gap),
                                             y: 30 + CGFloat(r) * (bh + gap),
                                             width: bw, height: bh))
                b.backgroundColor = colors[r]
                b.layer.cornerRadius = 2
                insertSubview(b, at: 0)
                bricks.append(b)
            }
        }
        score = 0
        lives = 3
        paddle.frame = CGRect(x: (bounds.width - 56) / 2, y: bounds.height - 24, width: 56, height: 8)
        resetBall()
        setState(.ready)
    }

    /// Wheel rotation in degrees.
    func rotate(_ deg: CGFloat) {
        guard state == .ready || state == .playing else { return }
        var f = paddle.frame
        f.origin.x = max(0, min(bounds.width - f.width, f.origin.x + deg * 1.3))
        paddle.frame = f
        if state == .ready { resetBall() }
    }

    /// Center button.
    func press() {
        switch state {
        case .ready:
            vel = CGPoint(x: baseSpeed * 0.5, y: -baseSpeed * 0.87)
            setState(.playing)
        case .playing:
            setState(.paused)
        case .paused:
            lastTime = CACurrentMediaTime()
            setState(.playing)
        case .over, .won:
            newGame()
        }
    }

    // MARK: Game loop
    private func resetBall() {
        ball.frame = CGRect(x: paddle.frame.midX - ballR, y: paddle.frame.minY - 2 * ballR - 1,
                            width: 2 * ballR, height: 2 * ballR)
        vel = .zero
    }

    private func setState(_ s: State) {
        state = s
        switch s {
        case .ready:   msgLabel.text = "Turn wheel to move\nPress center to launch"
        case .playing: msgLabel.text = ""
        case .paused:  msgLabel.text = "Paused\nPress center"
        case .over:    msgLabel.text = "Game Over\nScore \(score)\nPress center"
        case .won:     msgLabel.text = "You Win!\nScore \(score)\nPress center"
        }
        msgLabel.isHidden = (s == .playing)
        scoreLabel.text = "Score \(score)    Lives \(lives)"
    }

    @objc private func tick(_ l: CADisplayLink) {
        var dt = CGFloat(l.timestamp - lastTime)
        lastTime = l.timestamp
        guard state == .playing else { return }
        if dt > 1.0 / 30.0 { dt = 1.0 / 30.0 }

        var p = ball.center
        p.x += vel.x * dt
        p.y += vel.y * dt

        // Walls
        if p.x < ballR { p.x = ballR; vel.x = abs(vel.x) }
        if p.x > bounds.width - ballR { p.x = bounds.width - ballR; vel.x = -abs(vel.x) }
        if p.y < ballR { p.y = ballR; vel.y = abs(vel.y) }

        // Paddle
        let pr = paddle.frame
        if vel.y > 0, p.y + ballR >= pr.minY, p.y - ballR <= pr.maxY,
           p.x >= pr.minX - ballR, p.x <= pr.maxX + ballR {
            let rel = max(-1, min(1, (p.x - pr.midX) / (pr.width / 2)))
            let speed = hypot(vel.x, vel.y)
            let angle = rel * (.pi / 3)
            vel = CGPoint(x: speed * sin(angle), y: -speed * cos(angle))
            p.y = pr.minY - ballR
        }

        // Bricks
        for b in bricks where !b.isHidden {
            let f = b.frame
            let cx = max(f.minX, min(p.x, f.maxX))
            let cy = max(f.minY, min(p.y, f.maxY))
            let dx = p.x - cx, dy = p.y - cy
            if dx * dx + dy * dy <= ballR * ballR {
                if dx == 0 && dy == 0 {
                    vel.y = -vel.y
                } else if abs(dx) > abs(dy) {
                    vel.x = dx > 0 ? abs(vel.x) : -abs(vel.x)
                } else {
                    vel.y = dy > 0 ? abs(vel.y) : -abs(vel.y)
                }
                b.isHidden = true
                score += 10
                let speed = hypot(vel.x, vel.y)
                if speed < 380 { vel = CGPoint(x: vel.x * 1.015, y: vel.y * 1.015) }
                break
            }
        }
        ball.center = p
        scoreLabel.text = "Score \(score)    Lives \(lives)"

        if !bricks.contains(where: { !$0.isHidden }) {
            setState(.won)
            return
        }

        // Missed the ball
        if p.y - ballR > bounds.height {
            lives -= 1
            if lives <= 0 {
                setState(.over)
            } else {
                resetBall()
                setState(.ready)
            }
        }
    }
}
