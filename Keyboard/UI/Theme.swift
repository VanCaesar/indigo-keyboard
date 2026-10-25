import UIKit

/// 键盘配色。靛蓝只用于：首选候选、发送键、按下高亮。
struct Theme: Equatable {
    let isDark: Bool
    let background: UIColor
    let letterKey: UIColor
    let functionKey: UIColor
    let keyText: UIColor
    let keyShadow: UIColor
    let secondaryText: UIColor
    let indigo: UIColor
    let onIndigo: UIColor

    static let light = Theme(
        isDark: false,
        background: UIColor(hex: 0xD1D3D9),
        letterKey: .white,
        functionKey: UIColor(hex: 0xABB0BC),
        keyText: .black,
        keyShadow: UIColor(hex: 0x898A8D),
        secondaryText: UIColor(hex: 0x6E6E73),
        indigo: UIColor(hex: 0x5B54C9),
        onIndigo: .white
    )

    static let dark = Theme(
        isDark: true,
        background: UIColor(hex: 0x2B2B2D),
        letterKey: UIColor(hex: 0x6B6B6E),
        functionKey: UIColor(hex: 0x464649),
        keyText: .white,
        keyShadow: UIColor(white: 0, alpha: 0.6),
        secondaryText: UIColor(hex: 0xA1A1A6),
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
