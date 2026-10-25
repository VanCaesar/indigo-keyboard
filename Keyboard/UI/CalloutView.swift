import UIKit

/// 按下字母键时弹出的放大气泡（靛蓝），盖住按键并向上延伸
final class CalloutView: UIView {
    private let shape = CAShapeLayer()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.addSublayer(shape)
        shape.shadowColor = UIColor.black.cgColor
        shape.shadowOpacity = 0.25
        shape.shadowRadius = 2
        shape.shadowOffset = CGSize(width: 0, height: 1)
        label.textAlignment = .center
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError() }

    /// keyFrame 为按键在父视图中的位置；bounds 为可绘制范围（不能超出键盘扩展视图）
    func show(text: String, keyFrame k: CGRect, within limit: CGRect, theme: Theme, fontSize: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let neck: CGFloat = 8
        let bubbleWidth = k.width + min(24, k.width * 0.6)
        let bubbleHeight = k.height + 4
        var bx = k.midX - bubbleWidth / 2
        bx = max(limit.minX + 1, min(bx, limit.maxX - bubbleWidth - 1))
        let by = max(limit.minY + 1, k.minY - neck - bubbleHeight)
        let b = CGRect(x: bx, y: by, width: bubbleWidth, height: k.minY - neck - by)

        frame = limit
        let o = limit.origin
        let key = k.offsetBy(dx: -o.x, dy: -o.y)
        let bubble = b.offsetBy(dx: -o.x, dy: -o.y)

        shape.path = Self.path(key: key, bubble: bubble).cgPath
        shape.fillColor = theme.indigo.cgColor
        shape.frame = bounds

        label.text = text
        label.font = .systemFont(ofSize: fontSize, weight: .regular)
        label.textColor = theme.onIndigo
        label.frame = bubble
        isHidden = false
        CATransaction.commit()
    }

    func hide() {
        isHidden = true
    }

    private static func path(key k: CGRect, bubble b: CGRect) -> UIBezierPath {
        let r: CGFloat = 5
        let rb: CGFloat = 8
        let p = UIBezierPath()
        p.move(to: CGPoint(x: k.minX + r, y: k.maxY))
        p.addLine(to: CGPoint(x: k.maxX - r, y: k.maxY))
        p.addArc(withCenter: CGPoint(x: k.maxX - r, y: k.maxY - r), radius: r,
                 startAngle: .pi / 2, endAngle: 0, clockwise: false)
        p.addLine(to: CGPoint(x: k.maxX, y: k.minY))
        p.addQuadCurve(to: CGPoint(x: b.maxX, y: b.maxY - rb), controlPoint: CGPoint(x: k.maxX, y: b.maxY))
        p.addLine(to: CGPoint(x: b.maxX, y: b.minY + rb))
        p.addArc(withCenter: CGPoint(x: b.maxX - rb, y: b.minY + rb), radius: rb,
                 startAngle: 0, endAngle: -.pi / 2, clockwise: false)
        p.addLine(to: CGPoint(x: b.minX + rb, y: b.minY))
        p.addArc(withCenter: CGPoint(x: b.minX + rb, y: b.minY + rb), radius: rb,
                 startAngle: -.pi / 2, endAngle: .pi, clockwise: false)
        p.addLine(to: CGPoint(x: b.minX, y: b.maxY - rb))
        p.addQuadCurve(to: CGPoint(x: k.minX, y: k.minY), controlPoint: CGPoint(x: k.minX, y: b.maxY))
        p.addLine(to: CGPoint(x: k.minX, y: k.maxY - r))
        p.addArc(withCenter: CGPoint(x: k.minX + r, y: k.maxY - r), radius: r,
                 startAngle: .pi, endAngle: .pi / 2, clockwise: false)
        p.close()
        return p
    }
}
