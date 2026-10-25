import UIKit

/// 按下字母键时浮在按键上方的放大气泡（仿 iOS 26：独立圆角矩形，玻璃材质），字用靛蓝
final class CalloutView: UIView {
    private let bubble = UIView()
    private let label = UILabel()
    /// iOS 26 上用系统玻璃效果；更早的系统退回纯色 + 阴影
    private var glass: UIVisualEffectView?
    private var glassTheme: Theme?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        bubble.layer.cornerCurve = .continuous
        bubble.layer.cornerRadius = 12
        bubble.layer.shadowColor = UIColor.black.cgColor
        bubble.layer.shadowOpacity = 0.18
        bubble.layer.shadowRadius = 8
        bubble.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.textAlignment = .center
        addSubview(bubble)
        if #available(iOS 26.0, *) {
            let effect = UIGlassEffect()
            let v = UIVisualEffectView(effect: effect)
            v.layer.cornerRadius = 12
            v.layer.cornerCurve = .continuous
            v.clipsToBounds = true
            bubble.addSubview(v)
            glass = v
        }
        bubble.addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError() }

    /// keyFrame 为按键在父视图中的位置；limit 为可绘制范围（不能超出键盘扩展视图）
    func show(text: String, keyFrame k: CGRect, within limit: CGRect, theme: Theme, fontSize: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let width = (k.width * 1.7).rounded()
        let height = (k.height * 1.52).rounded()
        let bottom = k.minY - 4
        var x = k.midX - width / 2
        x = max(limit.minX + 2, min(x, limit.maxX - width - 2))
        let top = max(limit.minY + 2, bottom - height)

        frame = limit
        bubble.frame = CGRect(x: x, y: top, width: width, height: bottom - top)
            .offsetBy(dx: -limit.minX, dy: -limit.minY)
        bubble.layer.shadowPath = UIBezierPath(roundedRect: bubble.bounds, cornerRadius: 12).cgPath
        if let glass {
            // 玻璃上叠一层半透明底色，保证白键上也看得清
            glass.frame = bubble.bounds
            if theme != glassTheme, #available(iOS 26.0, *) {
                let effect = UIGlassEffect()
                effect.tintColor = theme.callout.withAlphaComponent(0.6)
                glass.effect = effect
                glassTheme = theme
            }
            bubble.backgroundColor = .clear
            bubble.layer.shadowOpacity = 0.12
        } else {
            bubble.backgroundColor = theme.callout
        }

        label.text = text
        label.font = .systemFont(ofSize: fontSize, weight: .regular)
        label.textColor = theme.indigo
        label.frame = bubble.bounds
        isHidden = false
        CATransaction.commit()
    }

    func hide() {
        isHidden = true
    }
}
