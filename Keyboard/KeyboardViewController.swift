import UIKit

/// 键盘扩展入口（骨架，后续替换为 26 键布局）
final class KeyboardViewController: UIInputViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let label = UILabel()
        label.text = "靛蓝输入法 · 骨架"
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
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            next.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            next.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
        ])
    }
}
