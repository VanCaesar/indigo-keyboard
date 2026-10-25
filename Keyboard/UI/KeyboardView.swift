import UIKit

protocol KeyboardViewDelegate: AnyObject {
    /// 按下即触发（touchDown），长按删除时会重复调用
    func keyboardView(_ view: KeyboardView, didPress key: Key)
    /// 地球键需要把原始触摸事件交给系统
    func keyboardView(_ view: KeyboardView, globeEvent event: UIEvent)
}

/// 按键区。所有按键共用这一个视图处理触摸：
/// 按下（touchesBegan）立即响应，支持多指连按，按键之间的缝隙也算最近的键。
final class KeyboardView: UIView, UIInputViewAudioFeedback {
    weak var delegate: KeyboardViewDelegate?

    private(set) var rows: [KeyboardRow] = []
    private var keyViews: [[KeyView]] = []
    /// 每个键的可点击区域（含缝隙）
    private var hitFrames: [[CGRect]] = []

    private var activeTouches: [UITouch: (view: KeyView, callout: CalloutView?)] = [:]
    private var calloutPool: [CalloutView] = []

    private var repeatTimer: Timer?
    private weak var repeatTouch: UITouch?

    /// 气泡可绘制范围（键盘扩展视图内，坐标为本视图坐标）
    var calloutLimit: CGRect = .zero

    var context: KeyView.Context {
        didSet {
            guard context != oldValue else { return }
            for row in keyViews { for v in row { v.context = context } }
            if context.landscape != oldValue.landscape { setNeedsLayout() }
        }
    }

    var enableInputClicksWhenVisible: Bool { true }

    override init(frame: CGRect) {
        context = KeyView.Context(theme: .light, shift: .off, chinese: true, returnType: .default,
                                  returnEnabled: true, landscape: false)
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        clipsToBounds = false
    }

    required init?(coder: NSCoder) { fatalError() }

    func setRows(_ newRows: [KeyboardRow]) {
        cancelAllTouches()
        keyViews.flatMap { $0 }.forEach { $0.removeFromSuperview() }
        rows = newRows
        keyViews = newRows.map { row in
            row.keys.map { key in
                let v = KeyView(key: key, context: context)
                addSubview(v)
                return v
            }
        }
        // 立刻算好点击区域，避免和旧的按键错位
        hitFrames = []
        setNeedsLayout()
        layoutIfNeeded()
    }

    // MARK: - 布局

    private var metrics: (side: CGFloat, top: CGFloat, hGap: CGFloat, vGap: CGFloat) {
        context.landscape ? (3, 4, 6, 6) : (3, 6, 6, 12)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let m = metrics
        let width = bounds.width - m.side * 2
        let unit = width / KeyboardLayout.columns
        let rowCount = CGFloat(max(rows.count, 1))
        let rowPitch = (bounds.height - m.top) / rowCount

        hitFrames = []
        for (r, row) in rows.enumerated() {
            let fixed = row.keys.reduce(CGFloat(0)) { $0 + $1.width }
            let flexCount = CGFloat(row.keys.filter { $0.width == 0 }.count)
            let flexWidth = flexCount > 0
                ? max(unit, (KeyboardLayout.columns - row.inset * 2 - fixed) * unit / flexCount)
                : 0
            let y = m.top + CGFloat(r) * rowPitch
            var x = m.side + row.inset * unit
            var frames: [CGRect] = []
            for (i, key) in row.keys.enumerated() {
                let w = key.width == 0 ? flexWidth : key.width * unit
                let cell = CGRect(x: x, y: y, width: w, height: rowPitch)
                var visual = cell.insetBy(dx: m.hGap / 2, dy: m.vGap / 2)
                visual.origin.x += key.trimLeading * unit
                visual.size.width -= (key.trimLeading + key.trimTrailing) * unit
                keyViews[r][i].frame = visual
                var hit = cell
                if i == 0 { hit = hit.union(CGRect(x: 0, y: y, width: 1, height: rowPitch)) }
                if i == row.keys.count - 1 {
                    hit = hit.union(CGRect(x: bounds.width - 1, y: y, width: 1, height: rowPitch))
                }
                frames.append(hit)
                x += w
            }
            hitFrames.append(frames)
        }
    }

    private func keyView(at point: CGPoint) -> KeyView? {
        guard !rows.isEmpty, hitFrames.count == rows.count else { return nil }
        let m = metrics
        let rowPitch = (bounds.height - m.top) / CGFloat(rows.count)
        let r = min(max(Int((point.y - m.top) / rowPitch), 0), rows.count - 1)
        let frames = hitFrames[r]
        if let i = frames.firstIndex(where: { point.x >= $0.minX && point.x < $0.maxX }) {
            return keyViews[r][i]
        }
        // 兜底：取水平距离最近的键
        let i = frames.indices.min { abs(frames[$0].midX - point.x) < abs(frames[$1].midX - point.x) }
        return i.map { keyViews[r][$0] }
    }

    // MARK: - 触摸

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            guard let v = keyView(at: touch.location(in: self)) else { continue }
            if v.key.action == .globe, let event {
                delegate?.keyboardView(self, globeEvent: event)
            }
            // 新的按键按下时，正在长按的删除键停止重复
            stopRepeat()
            v.isPressed = true
            let callout = v.key.showsCallout ? showCallout(for: v) : nil
            activeTouches[touch] = (v, callout)
            delegate?.keyboardView(self, didPress: v.key)
            if v.key.action == .backspace {
                startRepeat(for: touch, key: v.key)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches, event: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches, event: event)
    }

    private func finish(_ touches: Set<UITouch>, event: UIEvent?) {
        for touch in touches {
            guard let entry = activeTouches.removeValue(forKey: touch) else { continue }
            if entry.view.key.action == .globe, let event {
                delegate?.keyboardView(self, globeEvent: event)
            }
            if !activeTouches.values.contains(where: { $0.view === entry.view }) {
                entry.view.isPressed = false
            }
            if let c = entry.callout {
                c.hide()
                calloutPool.append(c)
            }
            if touch === repeatTouch { stopRepeat() }
        }
    }

    private func cancelAllTouches() {
        stopRepeat()
        for (_, entry) in activeTouches {
            entry.view.isPressed = false
            if let c = entry.callout {
                c.hide()
                calloutPool.append(c)
            }
        }
        activeTouches.removeAll()
    }

    /// 仅用于预览截图：模拟按住某个键
    func simulatePress(_ action: KeyAction) {
        guard let v = keyViews.joined().first(where: { $0.key.action == action }) else { return }
        v.isPressed = true
        if v.key.showsCallout { _ = showCallout(for: v) }
    }

    // MARK: - 气泡

    private func showCallout(for v: KeyView) -> CalloutView {
        let c = calloutPool.popLast() ?? {
            let c = CalloutView()
            addSubview(c)
            return c
        }()
        bringSubviewToFront(c)
        let text: String
        switch v.key.action {
        case .letter(let ch): text = context.shift == .off ? String(ch) : String(ch).uppercased()
        case .symbol(let s): text = s
        default: text = ""
        }
        let limit = calloutLimit == .zero ? bounds : calloutLimit
        c.show(text: text, keyFrame: v.frame, within: limit, theme: context.theme,
               fontSize: context.landscape ? 34 : 44)
        return c
    }

    // MARK: - 长按删除

    private func startRepeat(for touch: UITouch, key: Key) {
        repeatTouch = touch
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
                guard let self else { return }
                self.delegate?.keyboardView(self, didPress: key)
            }
            RunLoop.main.add(self.repeatTimer!, forMode: .common)
        }
        RunLoop.main.add(repeatTimer!, forMode: .common)
    }

    private func stopRepeat() {
        repeatTimer?.invalidate()
        repeatTimer = nil
        repeatTouch = nil
    }
}
