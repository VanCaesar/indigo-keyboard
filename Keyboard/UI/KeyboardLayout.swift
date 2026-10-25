import UIKit

enum LayoutKind {
    case letters, numbers, symbols
}

enum ShiftState {
    case off, on, locked
}

enum KeyAction: Equatable {
    /// 字母：中文模式送 Rime，英文模式直接上屏
    case letter(Character)
    /// 数字、标点：直接上屏（中文模式下先把正在输入的拼音上屏首选）
    case symbol(String)
    case space
    case backspace
    case shift
    case returnKey
    case globe
    case toggleLanguage
    case layout(LayoutKind)
}

struct Key {
    let action: KeyAction
    /// 宽度，单位是一个字母键宽；0 表示占满剩余宽度
    let width: CGFloat
    /// 外观上从左/右侧收窄多少（单位同 width），点击区域不变。用于 shift、删除键旁边的大间距
    let trimLeading: CGFloat
    let trimTrailing: CGFloat

    init(_ action: KeyAction, width: CGFloat = 1, trimLeading: CGFloat = 0, trimTrailing: CGFloat = 0) {
        self.action = action
        self.width = width
        self.trimLeading = trimLeading
        self.trimTrailing = trimTrailing
    }

    /// 按下时是否弹出放大气泡
    var showsCallout: Bool {
        switch action {
        case .letter, .symbol: return true
        default: return false
        }
    }

    var isFunctionKey: Bool {
        switch action {
        case .letter, .symbol, .space: return false
        default: return true
        }
    }
}

struct KeyboardRow {
    let keys: [Key]
    /// 左右留白（单位同 Key.width），例如第二行字母两侧各半个键
    let inset: CGFloat

    init(_ keys: [Key], inset: CGFloat = 0) {
        self.keys = keys
        self.inset = inset
    }
}

/// 生成某种状态下的四行按键
struct KeyboardLayout {
    static let columns: CGFloat = 10

    static func rows(kind: LayoutKind, chinese: Bool, needsGlobe: Bool) -> [KeyboardRow] {
        let bottom = bottomRow(kind: kind, needsGlobe: needsGlobe)
        switch kind {
        case .letters:
            return [
                KeyboardRow("qwertyuiop".map { Key(.letter($0)) }),
                KeyboardRow("asdfghjkl".map { Key(.letter($0)) }, inset: 0.5),
                KeyboardRow([Key(.shift, width: 1.5, trimTrailing: 0.2)]
                            + "zxcvbnm".map { Key(.letter($0)) }
                            + [Key(.backspace, width: 1.5, trimLeading: 0.2)]),
                bottom,
            ]
        case .numbers:
            let row2 = chinese
                ? ["-", "/", "：", "；", "（", "）", "¥", "@", "“", "”"]
                : ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""]
            let row3 = chinese ? ["。", "，", "、", "？", "！"] : [".", ",", "?", "!", "'"]
            return [
                KeyboardRow("1234567890".map { Key(.symbol(String($0))) }),
                KeyboardRow(row2.map { Key(.symbol($0)) }),
                KeyboardRow([Key(.layout(.symbols), width: 1.5, trimTrailing: 0.2)]
                            + row3.map { Key(.symbol($0), width: 1.4) }
                            + [Key(.backspace, width: 1.5, trimLeading: 0.2)]),
                bottom,
            ]
        case .symbols:
            let row1 = chinese
                ? ["【", "】", "｛", "｝", "#", "%", "^", "*", "+", "="]
                : ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="]
            let row2 = chinese
                ? ["_", "—", "\\", "|", "～", "《", "》", "€", "&", "·"]
                : ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"]
            let row3 = chinese ? ["…", "，", "？", "！", "’"] : [".", ",", "?", "!", "'"]
            return [
                KeyboardRow(row1.map { Key(.symbol($0)) }),
                KeyboardRow(row2.map { Key(.symbol($0)) }),
                KeyboardRow([Key(.layout(.numbers), width: 1.5, trimTrailing: 0.2)]
                            + row3.map { Key(.symbol($0), width: 1.4) }
                            + [Key(.backspace, width: 1.5, trimLeading: 0.2)]),
                bottom,
            ]
        }
    }

    private static func bottomRow(kind: LayoutKind, needsGlobe: Bool) -> KeyboardRow {
        var keys: [Key] = [Key(.layout(kind == .letters ? .numbers : .letters), width: 1.25)]
        if needsGlobe { keys.append(Key(.globe, width: 1.25)) }
        if kind == .letters { keys.append(Key(.toggleLanguage, width: 1.25)) }
        keys.append(Key(.space, width: 0))
        keys.append(Key(.returnKey, width: 2.5))
        return KeyboardRow(keys)
    }

    /// 不在打字时候选栏显示的常用标点
    static func quickSymbols(chinese: Bool) -> [String] {
        chinese ? ["，", "。", "？", "！", "、", "……"] : [",", ".", "?", "!", "'", "@"]
    }

    /// 输入这些中文标点后自动回到字母键盘
    static let returnsToLetters: Set<String> = ["。", "，", "、", "？", "！", "：", "；", "…"]
}

extension UIReturnKeyType {
    /// 是否是「动作型」回车（发送、搜索等）：用靛蓝
    var isAction: Bool {
        switch self {
        case .default: return false
        default: return true
        }
    }

    var title: String {
        switch self {
        case .send: return "发送"
        case .search, .google, .yahoo: return "搜索"
        case .go: return "前往"
        case .done: return "完成"
        case .next: return "下一项"
        case .join: return "加入"
        case .route: return "路线"
        case .continue: return "继续"
        case .emergencyCall: return "紧急"
        default: return "换行"
        }
    }
}
