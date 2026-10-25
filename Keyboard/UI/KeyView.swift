import UIKit

/// 单个按键的外观。不接收触摸：触摸统一由 KeyboardView 处理。
final class KeyView: UIView {
    let key: Key
    private let label = UILabel()
    private let imageView = UIImageView()
    /// 空格键右下角的小字（拼 / 英）
    private let cornerLabel = UILabel()

    struct Context: Equatable {
        var theme: Theme
        var shift: ShiftState
        var chinese: Bool
        var returnType: UIReturnKeyType
        /// 输入框为空且设了「自动启用回车」时为 false，回车键显示为灰色禁用
        var returnEnabled: Bool
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
        layer.cornerCurve = .continuous
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        imageView.contentMode = .center
        cornerLabel.font = .systemFont(ofSize: 12)
        cornerLabel.textAlignment = .right
        addSubview(label)
        addSubview(imageView)
        addSubview(cornerLabel)
        refresh()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = context.landscape ? 7 : 8.5
        label.frame = bounds.insetBy(dx: 2, dy: 0)
        imageView.frame = bounds
        cornerLabel.frame = CGRect(x: 0, y: bounds.height - 18, width: bounds.width - 9, height: 14)
    }

    // MARK: - 内容

    private func refresh() {
        label.attributedText = nil
        label.text = nil
        imageView.image = nil
        cornerLabel.text = nil
        let letterSize: CGFloat = context.landscape ? 22 : 25

        switch key.action {
        case .letter(let ch):
            label.font = .systemFont(ofSize: letterSize, weight: .regular)
            label.text = context.shift == .off ? String(ch) : String(ch).uppercased()
        case .symbol(let s):
            label.font = .systemFont(ofSize: letterSize - 1, weight: .regular)
            label.text = s
        case .space:
            cornerLabel.text = context.chinese ? "拼" : "英"
        case .returnKey:
            let color = returnForeground
            if let name = context.returnType.symbolName {
                imageView.image = symbol(name, color: color)
            } else {
                label.font = .systemFont(ofSize: 17, weight: .medium)
                label.text = context.returnType.title
            }
        case .layout(let kind):
            label.font = .systemFont(ofSize: 18)
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
        setNeedsLayout()
    }

    private func languageTitle() -> NSAttributedString {
        let theme = context.theme
        let big: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 18),
                                                  .foregroundColor: theme.keyText]
        let small: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12),
                                                    .foregroundColor: theme.secondaryText]
        let s = NSMutableAttributedString()
        s.append(NSAttributedString(string: "中", attributes: context.chinese ? big : small))
        s.append(NSAttributedString(string: "/", attributes: small))
        s.append(NSAttributedString(string: "英", attributes: context.chinese ? small : big))
        return s
    }

    private func symbol(_ name: String, color: UIColor? = nil) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        return UIImage(systemName: name, withConfiguration: config)?
            .withTintColor(color ?? context.theme.keyText, renderingMode: .alwaysOriginal)
    }

    /// 发送/搜索类回车键：可用时靛蓝底白字，禁用时灰底灰字
    private var isActionReturn: Bool {
        key.action == .returnKey && context.returnType.isAction
    }

    private var returnForeground: UIColor {
        guard isActionReturn else { return context.theme.keyText }
        return context.returnEnabled ? context.theme.onIndigo : context.theme.secondaryText
    }

    // MARK: - 颜色

    private func applyColors() {
        let theme = context.theme
        var textColor = theme.keyText

        if isActionReturn {
            // 发送键：靛蓝；输入框为空时灰色禁用
            if context.returnEnabled {
                backgroundColor = isPressed ? theme.indigo.withAlphaComponent(0.75) : theme.indigo
            } else {
                backgroundColor = theme.disabledKey
            }
            textColor = returnForeground
        } else {
            // 和系统一样所有键同色；按下时变淡（字母键上方另有气泡）
            backgroundColor = isPressed ? theme.pressedKey : theme.key
            if isPressed, key.showsCallout { textColor = theme.secondaryText }
        }
        if key.action != .toggleLanguage {
            label.textColor = textColor
        }
        cornerLabel.textColor = theme.secondaryText
    }
}
