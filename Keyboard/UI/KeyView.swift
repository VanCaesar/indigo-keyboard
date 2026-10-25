import UIKit

/// 单个按键的外观。不接收触摸：触摸统一由 KeyboardView 处理。
final class KeyView: UIView {
    let key: Key
    private let label = UILabel()
    private let imageView = UIImageView()

    struct Context: Equatable {
        var theme: Theme
        var shift: ShiftState
        var chinese: Bool
        var returnType: UIReturnKeyType
        var landscape: Bool
    }

    var context: Context {
        didSet { if context != oldValue { refresh() } }
    }

    var isPressed = false {
        didSet { if isPressed != oldValue { applyColors() } }
    }

    init(key: Key, context: Context) {
        self.key = key
        self.context = context
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        layer.cornerRadius = 5
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 0
        layer.shadowOpacity = 1
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        imageView.contentMode = .center
        addSubview(label)
        addSubview(imageView)
        refresh()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds.insetBy(dx: 2, dy: 0)
        imageView.frame = bounds
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }

    // MARK: - 内容

    private func refresh() {
        label.attributedText = nil
        label.text = nil
        imageView.image = nil
        let letterSize: CGFloat = context.landscape ? 20 : 23

        switch key.action {
        case .letter(let ch):
            label.font = .systemFont(ofSize: letterSize, weight: .regular)
            label.text = context.shift == .off ? String(ch) : String(ch).uppercased()
        case .symbol(let s):
            label.font = .systemFont(ofSize: letterSize - 1, weight: .regular)
            label.text = s
        case .space:
            label.font = .systemFont(ofSize: 16)
            label.text = context.chinese ? "空格" : "space"
        case .returnKey:
            label.font = .systemFont(ofSize: 16)
            label.text = context.returnType.title
        case .layout(let kind):
            label.font = .systemFont(ofSize: 16)
            switch kind {
            case .letters: label.text = context.chinese ? "拼音" : "ABC"
            case .numbers: label.text = "123"
            case .symbols: label.text = "#+="
            }
        case .toggleLanguage:
            label.attributedText = languageTitle()
        case .shift:
            let name: String
            switch context.shift {
            case .off: name = "shift"
            case .on: name = "shift.fill"
            case .locked: name = "capslock.fill"
            }
            imageView.image = symbol(name)
        case .backspace:
            imageView.image = symbol("delete.left")
        case .globe:
            imageView.image = symbol("globe")
        }
        applyColors()
    }

    private func languageTitle() -> NSAttributedString {
        let theme = context.theme
        let big: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17, weight: .medium),
                                                  .foregroundColor: theme.keyText]
        let small: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12),
                                                    .foregroundColor: theme.secondaryText]
        let s = NSMutableAttributedString()
        s.append(NSAttributedString(string: "中", attributes: context.chinese ? big : small))
        s.append(NSAttributedString(string: "/", attributes: small))
        s.append(NSAttributedString(string: "英", attributes: context.chinese ? small : big))
        return s
    }

    private func symbol(_ name: String) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        return UIImage(systemName: name, withConfiguration: config)?
            .withTintColor(context.theme.keyText, renderingMode: .alwaysOriginal)
    }

    // MARK: - 颜色

    private func applyColors() {
        let theme = context.theme
        layer.shadowColor = theme.keyShadow.cgColor
        var textColor = theme.keyText

        switch key.action {
        case .returnKey where context.returnType.isAction:
            backgroundColor = isPressed ? theme.indigo.withAlphaComponent(0.75) : theme.indigo
            textColor = theme.onIndigo
        case .letter, .symbol, .space:
            // 按下高亮：靛蓝
            backgroundColor = isPressed ? theme.indigo : theme.letterKey
            if isPressed { textColor = theme.onIndigo }
        default:
            // 功能键按下时和字母键对调颜色，与系统一致
            backgroundColor = isPressed ? theme.letterKey : theme.functionKey
        }
        if key.action != .toggleLanguage {
            label.textColor = textColor
        }
    }
}
