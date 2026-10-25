import UIKit

/// 主 App：引导开启键盘 + 试打区
final class HomeViewController: UIViewController {
    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "靛蓝输入法"
        view.backgroundColor = .systemGroupedBackground

        let steps = UILabel()
        steps.numberOfLines = 0
        steps.font = .preferredFont(forTextStyle: .body)
        steps.text = """
        开启步骤：
        1. 设置 → 通用 → 键盘 → 键盘 → 添加新键盘 → 靛蓝
        2. 点「靛蓝」，打开「允许完全访问」（震动需要）
        3. 回到这里，在下面输入框里按地球键切换到靛蓝试打
        """

        let button = UIButton(type: .system)
        button.setTitle("打开设置", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        textView.font = .preferredFont(forTextStyle: .body)
        textView.layer.cornerRadius = 10
        textView.backgroundColor = .secondarySystemGroupedBackground
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)

        let stack = UIStackView(arrangedSubviews: [steps, button, textView])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            textView.heightAnchor.constraint(equalToConstant: 160),
        ])
    }

    @objc private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
