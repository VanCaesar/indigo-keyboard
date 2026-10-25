import UIKit

/// 键盘配色（仿 iOS 26 系统键盘：所有键同色、无阴影）。
/// 靛蓝只用于：首选候选、发送键、按下高亮（气泡里的字）。
struct Theme: Equatable {
    let isDark: Bool
    /// 键盘底色。键盘扩展里不画，用系统自带的键盘背景；预览界面里用它模拟
    let background: UIColor
    let key: UIColor
    let pressedKey: UIColor
    let callout: UIColor
    let keyText: UIColor
    let secondaryText: UIColor
    let indigo: UIColor
    let onIndigo: UIColor

    static let light = Theme(
        isDark: false,
        background: UIColor(hex: 0xE0E1E6),
        key: .white,
        pressedKey: UIColor(white: 1, alpha: 0.45),
        callout: .white,
        keyText: .black,
        secondaryText: UIColor(hex: 0x8E8E93),
        indigo: UIColor(hex: 0x5B54C9),
        onIndigo: .white
    )

    static let dark = Theme(
        isDark: true,
        background: UIColor(hex: 0x2A2A2C),
        key: UIColor(hex: 0x5E5E62),
        pressedKey: UIColor(hex: 0x5E5E62, alpha: 0.45),
        callout: UIColor(hex: 0x6E6E73),
        keyText: .white,
        secondaryText: UIColor(hex: 0x98989D),
        indigo: UIColor(hex: 0x8B85E6),
        onIndigo: .white
    )
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}
