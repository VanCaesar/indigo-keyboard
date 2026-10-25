import UIKit

/// 预览截图用：在 App 里摆出和键盘扩展一样的候选栏与按键（不接 Rime，候选是示例数据）
final class PreviewViewController: UIViewController {
    private let numbers: Bool
    private let theme: Theme
    private let candidateBar = CandidateBar()
    private let keyboardView = KeyboardView()
    private let keyboardArea = UIView()

    init(numbers: Bool, dark: Bool) {
        self.numbers = numbers
        self.theme = dark ? .dark : .light
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let field = UILabel()
        field.text = numbers ? "  今天天气不错" : "  今天"
        field.font = .systemFont(ofSize: 17)
        field.backgroundColor = .secondarySystemBackground
        field.layer.cornerRadius = 18
        field.layer.masksToBounds = true

        keyboardArea.backgroundColor = theme.background
        candidateBar.theme = theme
        candidateBar.update(preedit: numbers ? "" : "ni hao",
                            candidates: numbers ? [] : ["你好", "你", "尼", "泥", "妮", "拟", "你号", "倪", "腻"])
        keyboardView.backgroundColor = theme.background
        keyboardView.context = KeyView.Context(theme: theme, shift: .off, chinese: true,
                                               returnType: .send, landscape: false)
        keyboardView.setRows(KeyboardLayout.rows(kind: numbers ? .numbers : .letters,
                                                 chinese: true, needsGlobe: false))

        for v in [field, keyboardArea, candidateBar, keyboardView] {
            v.translatesAutoresizingMaskIntoConstraints = false
        }
        view.addSubview(field)
        view.addSubview(keyboardArea)
        keyboardArea.addSubview(candidateBar)
        keyboardArea.addSubview(keyboardView)

        NSLayoutConstraint.activate([
            keyboardArea.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardArea.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardArea.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            candidateBar.topAnchor.constraint(equalTo: keyboardArea.topAnchor),
            candidateBar.leadingAnchor.constraint(equalTo: keyboardArea.leadingAnchor),
            candidateBar.trailingAnchor.constraint(equalTo: keyboardArea.trailingAnchor),
            candidateBar.heightAnchor.constraint(equalToConstant: CandidateBar.height),
            keyboardView.topAnchor.constraint(equalTo: candidateBar.bottomAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: keyboardArea.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: keyboardArea.trailingAnchor),
            keyboardView.heightAnchor.constraint(equalToConstant: 216),
            // 系统在键盘下方留的地球/麦克风区
            keyboardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            field.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            field.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            field.heightAnchor.constraint(equalToConstant: 36),
            field.bottomAnchor.constraint(equalTo: keyboardArea.topAnchor, constant: -8),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        keyboardView.calloutLimit = keyboardArea.convert(keyboardArea.bounds, to: keyboardView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 模拟按住一个键，展示靛蓝高亮与气泡
        keyboardView.simulatePress(numbers ? .symbol("，") : .letter("h"))
    }
}
