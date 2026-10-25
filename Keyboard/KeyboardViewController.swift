import UIKit

/// 键盘扩展入口（骨架：加载 Rime 并自测 nihao，后续替换为 26 键布局）
final class KeyboardViewController: UIInputViewController {
    private let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = "正在加载 Rime…"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        let next = UIButton(type: .system)
        next.setTitle("🌐", for: .normal)
        next.translatesAutoresizingMaskIntoConstraints = false
        next.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        view.addSubview(next)

        let height = view.heightAnchor.constraint(equalToConstant: 260)
        height.priority = .defaultHigh
        NSLayoutConstraint.activate([
            height,
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -24),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            next.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            next.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
        ])
        selfTest()
    }

    private func selfTest() {
        let start = CACurrentMediaTime()
        RimeEngine.shared.start { [weak self] ok in
            guard let self else { return }
            guard ok else { label.text = "Rime 加载失败"; return }
            let loaded = CACurrentMediaTime()
            let keys = Array("nihao".unicodeScalars)
            for (i, ch) in keys.enumerated() {
                RimeEngine.shared.process(keycode: Int32(ch.value)) { _, snap in
                    guard i == keys.count - 1 else { return }
                    let ms = Int((loaded - start) * 1000)
                    self.label.text = "Rime 已加载（\(ms)ms）\n\(snap.preedit) → " + snap.candidates.prefix(5).joined(separator: " ")
                    RimeEngine.shared.reset()
                }
            }
        }
    }
}
