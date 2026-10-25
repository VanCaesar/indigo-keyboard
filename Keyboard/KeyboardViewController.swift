import UIKit

/// 键盘扩展入口：把按键、候选栏和 Rime 接起来。
/// 主线程只做绘制和上屏；Rime 调用都在 RimeEngine 的后台串行队列里。
final class KeyboardViewController: UIInputViewController {
    private let candidateBar = CandidateBar()
    private let keyboardView = KeyboardView()
    private let feedback = Feedback()
    private var heightConstraint: NSLayoutConstraint?

    private var layoutKind: LayoutKind = .letters
    private var shift: ShiftState = .off
    private var lastShiftTap: CFTimeInterval = 0
    private var chinese = true
    private var needsGlobe = false

    /// 最近一次 Rime 状态
    private var snapshot = RimeSnapshot()
    /// 已发给 Rime 但还没回来的操作数；不为 0 时所有上屏都要排队，保证顺序
    private var pendingRime = 0
    private var loadingMore = false

    private var rimeBusy: Bool { snapshot.isComposing || pendingRime > 0 }

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        RimeEngine.shared.start()

        candidateBar.delegate = self
        keyboardView.delegate = self
        candidateBar.translatesAutoresizingMaskIntoConstraints = false
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(candidateBar)
        view.addSubview(keyboardView)
        NSLayoutConstraint.activate([
            candidateBar.topAnchor.constraint(equalTo: view.topAnchor),
            candidateBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            candidateBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            candidateBar.heightAnchor.constraint(equalToConstant: CandidateBar.height),
            keyboardView.topAnchor.constraint(equalTo: candidateBar.bottomAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        let height = view.heightAnchor.constraint(equalToConstant: keyboardHeight)
        height.priority = UILayoutPriority(999)
        height.isActive = true
        heightConstraint = height

        needsGlobe = needsInputModeSwitchKey
        updateContext()
        reloadRows()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        feedback.hapticsEnabled = hasFullAccess
        feedback.prepare()
        if needsGlobe != needsInputModeSwitchKey {
            needsGlobe = needsInputModeSwitchKey
            reloadRows()
        }
        updateContext()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        clearComposition()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        keyboardView.calloutLimit = view.convert(view.bounds, to: keyboardView)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        heightConstraint?.constant = keyboardHeight
        updateContext()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateContext()
    }

    private var isLandscape: Bool {
        traitCollection.verticalSizeClass == .compact
    }

    private var keyboardHeight: CGFloat {
        CandidateBar.height + (isLandscape ? 160 : 216)
    }

    private var theme: Theme {
        if textDocumentProxy.keyboardAppearance == .dark { return .dark }
        return traitCollection.userInterfaceStyle == .dark ? .dark : .light
    }

    private func updateContext() {
        let t = theme
        view.backgroundColor = t.background
        candidateBar.theme = t
        keyboardView.backgroundColor = t.background
        keyboardView.context = KeyView.Context(
            theme: t,
            shift: shift,
            chinese: chinese,
            returnType: textDocumentProxy.returnKeyType ?? .default,
            landscape: isLandscape
        )
    }

    private func reloadRows() {
        keyboardView.setRows(KeyboardLayout.rows(kind: layoutKind, chinese: chinese, needsGlobe: needsGlobe))
    }

    // MARK: - 上屏

    private func insert(_ text: String) {
        textDocumentProxy.insertText(text)
    }

    private func apply(_ snap: RimeSnapshot) {
        if let text = snap.commitText { insert(text) }
        snapshot = snap
        loadingMore = false
        candidateBar.update(preedit: snap.preedit, candidates: snap.candidates)
    }

    /// 等 Rime 队列空了再执行（不在输入拼音时直接执行，最快）
    private func afterRime(_ work: @escaping () -> Void) {
        guard pendingRime > 0 else { work(); return }
        pendingRime += 1
        RimeEngine.shared.sync { [weak self] in
            self?.pendingRime -= 1
            work()
        }
    }

    private func sendToRime(_ keycode: Int32, unhandled: (() -> Void)? = nil) {
        pendingRime += 1
        RimeEngine.shared.process(keycode: keycode) { [weak self] handled, snap in
            guard let self else { return }
            pendingRime -= 1
            apply(snap)
            if !handled { unhandled?() }
        }
    }

    private func clearComposition() {
        RimeEngine.shared.reset()
        snapshot = RimeSnapshot()
        candidateBar.update(preedit: "", candidates: [])
    }

    // MARK: - 按键

    private func typeLetter(_ ch: Character) {
        let text = shift == .off ? String(ch) : String(ch).uppercased()
        if shift == .on {
            shift = .off
            updateContext()
        }
        if chinese, let scalar = text.unicodeScalars.first {
            sendToRime(Int32(scalar.value)) { [weak self] in self?.insert(text) }
        } else {
            afterRime { [weak self] in self?.insert(text) }
        }
    }

    private func typeSymbol(_ text: String) {
        if rimeBusy {
            pendingRime += 1
            RimeEngine.shared.commitComposition { [weak self] snap in
                guard let self else { return }
                pendingRime -= 1
                apply(snap)
                insert(text)
            }
        } else {
            insert(text)
        }
        if chinese, layoutKind != .letters, KeyboardLayout.returnsToLetters.contains(text) {
            setLayout(.letters)
        }
    }

    private func typeSpace() {
        if chinese, rimeBusy {
            sendToRime(RimeKey.space) { [weak self] in self?.insert(" ") }
        } else {
            afterRime { [weak self] in self?.insert(" ") }
        }
        if layoutKind != .letters { setLayout(.letters) }
    }

    private func typeReturn() {
        if rimeBusy {
            sendToRime(RimeKey.returnKey) { [weak self] in self?.insert("\n") }
        } else {
            insert("\n")
        }
    }

    private func backspace() {
        if rimeBusy {
            sendToRime(RimeKey.backspace) { [weak self] in self?.textDocumentProxy.deleteBackward() }
        } else {
            textDocumentProxy.deleteBackward()
        }
    }

    private func tapShift() {
        let now = CACurrentMediaTime()
        let isDoubleTap = now - lastShiftTap < 0.3
        lastShiftTap = now
        switch shift {
        case .off: shift = .on
        case .on: shift = isDoubleTap ? .locked : .off
        case .locked: shift = .off
        }
        updateContext()
    }

    private func toggleLanguage() {
        if rimeBusy {
            // 切到英文时，已打的拼音原样上屏
            pendingRime += 1
            RimeEngine.shared.commitRawInput { [weak self] snap in
                guard let self else { return }
                pendingRime -= 1
                apply(snap)
            }
        }
        chinese.toggle()
        shift = .off
        updateContext()
        reloadRows()
    }

    private func setLayout(_ kind: LayoutKind) {
        guard kind != layoutKind else { return }
        layoutKind = kind
        if shift != .off {
            shift = .off
            updateContext()
        }
        reloadRows()
    }
}

// MARK: - KeyboardViewDelegate

extension KeyboardViewController: KeyboardViewDelegate {
    func keyboardView(_ view: KeyboardView, didPress key: Key) {
        feedback.keyDown()
        switch key.action {
        case .letter(let ch): typeLetter(ch)
        case .symbol(let s): typeSymbol(s)
        case .space: typeSpace()
        case .backspace: backspace()
        case .shift: tapShift()
        case .returnKey: typeReturn()
        case .globe: break
        case .toggleLanguage: toggleLanguage()
        case .layout(let kind): setLayout(kind)
        }
    }

    func keyboardView(_ view: KeyboardView, globeEvent event: UIEvent) {
        handleInputModeList(from: view, with: event)
    }
}

// MARK: - CandidateBarDelegate

extension KeyboardViewController: CandidateBarDelegate {
    func candidateBar(_ bar: CandidateBar, didSelect index: Int) {
        feedback.keyDown()
        pendingRime += 1
        RimeEngine.shared.select(index: index, revision: snapshot.revision) { [weak self] snap in
            guard let self else { return }
            pendingRime -= 1
            if let snap { apply(snap) }
        }
    }

    func candidateBarNeedsMore(_ bar: CandidateBar) {
        guard snapshot.mayHaveMore, !loadingMore, pendingRime == 0 else { return }
        loadingMore = true
        let revision = snapshot.revision
        RimeEngine.shared.moreCandidates(from: snapshot.candidates.count, revision: revision) { [weak self] list in
            guard let self, revision == self.snapshot.revision else { return }
            loadingMore = false
            snapshot.candidates += list
            snapshot.mayHaveMore = list.count == RimeEngine.candidateBatch
            bar.append(list)
        }
    }

    func candidateBarDismissKeyboard(_ bar: CandidateBar) {
        dismissKeyboard()
    }
}
