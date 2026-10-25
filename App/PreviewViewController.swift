import UIKit

/// 预览截图用：在 App 里摆出和键盘扩展一样的候选栏与按键（不接 Rime，候选是示例数据）。
/// 键盘外面的圆角底板和地球/麦克风那一行在真机上由系统画，这里只是模拟。
final class PreviewViewController: UIViewController {
    enum Mode: String {
        /// 正在打拼音，按住 h
        case letters
        /// 没在打字，候选栏显示常用标点
        case idle
        /// 数字符号页，按住「，」
        case numbers
    }

    private let mode: Mode
    private let theme: Theme
    private let candidateBar = CandidateBar()
    private let keyboardView = KeyboardView()
    private let keyboardArea = UIView()

    init(mode: Mode, dark: Bool) {
        self.mode = mode
        self.theme = dark ? .dark : .light
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let field = UILabel()
        field.text = mode == .letters ? "  今天" : "  今天天气不错"
        field.font = .systemFont(ofSize: 17)
        field.backgroundColor = .secondarySystemBackground
        field.layer.cornerRadius = 18
        field.layer.masksToBounds = true

        keyboardArea.backgroundColor = theme.background
        keyboardArea.layer.cornerRadius = 32
        keyboardArea.layer.cornerCurve = .continuous

        candidateBar.theme = theme
        candidateBar.quickSymbols = KeyboardLayout.quickSymbols(chinese: true)
        if mode == .letters {
            candidateBar.update(preedit: "ni hao",
                                candidates: ["你好", "你", "尼", "泥", "妮", "拟", "你号", "倪", "腻"])
        }
        keyboardView.context = KeyView.Context(theme: theme, shift: .off, chinese: true,
                                               returnType: mode == .idle ? .default : .send,
                                               landscape: false)
        keyboardView.setRows(KeyboardLayout.rows(kind: mode == .numbers ? .numbers : .letters,
                                                 chinese: true, needsGlobe: false))

        let globe = systemIcon("globe")
        let mic = systemIcon("mic")

        for v in [field, keyboardArea, candidateBar, keyboardView, globe, mic] {
            v.translatesAutoresizingMaskIntoConstraints = false
        }
        view.addSubview(field)
        view.addSubview(keyboardArea)
        keyboardArea.addSubview(candidateBar)
        keyboardArea.addSubview(keyboardView)
        keyboardArea.addSubview(globe)
        keyboardArea.addSubview(mic)

        NSLayoutConstraint.activate([
            keyboardArea.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardArea.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardArea.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            candidateBar.topAnchor.constraint(equalTo: keyboardArea.topAnchor, constant: 6),
            candidateBar.leadingAnchor.constraint(equalTo: keyboardArea.leadingAnchor),
            candidateBar.trailingAnchor.constraint(equalTo: keyboardArea.trailingAnchor),
            candidateBar.heightAnchor.constraint(equalToConstant: CandidateBar.height),
            keyboardView.topAnchor.constraint(equalTo: candidateBar.bottomAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: keyboardArea.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: keyboardArea.trailingAnchor),
            keyboardView.heightAnchor.constraint(equalToConstant: 216),
            // 系统在键盘下方留的地球/麦克风区
            keyboardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -44),
            globe.leadingAnchor.constraint(equalTo: keyboardArea.leadingAnchor, constant: 28),
            globe.topAnchor.constraint(equalTo: keyboardView.bottomAnchor, constant: 10),
            mic.trailingAnchor.constraint(equalTo: keyboardArea.trailingAnchor, constant: -30),
            mic.centerYAnchor.constraint(equalTo: globe.centerYAnchor),
            field.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            field.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            field.heightAnchor.constraint(equalToConstant: 36),
            field.bottomAnchor.constraint(equalTo: keyboardArea.topAnchor, constant: -8),
        ])
    }

    private func systemIcon(_ name: String) -> UIImageView {
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        let v = UIImageView(image: UIImage(systemName: name, withConfiguration: config))
        v.tintColor = theme.keyText
        return v
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        keyboardView.calloutLimit = keyboardArea.convert(keyboardArea.bounds, to: keyboardView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 模拟按住一个键，展示按下效果与气泡
        switch mode {
        case .letters: keyboardView.simulatePress(.letter("h"))
        case .numbers: keyboardView.simulatePress(.symbol("，"))
        case .idle: break
        }
    }
}
