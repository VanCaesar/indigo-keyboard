import UIKit

/// 按键反馈：震动（需要完全访问）+ 系统键盘按键音（跟随系统设置）
final class Feedback {
    private let generator = UIImpactFeedbackGenerator(style: .light)
    var hapticsEnabled = false

    func prepare() {
        if hapticsEnabled { generator.prepare() }
    }

    func keyDown() {
        if hapticsEnabled {
            generator.impactOccurred(intensity: 0.75)
            generator.prepare()
        }
        UIDevice.current.playInputClick()
    }
}
