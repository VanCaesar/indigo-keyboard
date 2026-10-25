import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UINavigationController(rootViewController: HomeViewController())
        window.tintColor = Indigo.color
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

enum Indigo {
    /// 浅色 #5B54C9，深色 #8B85E6
    static let color = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x8B / 255.0, green: 0x85 / 255.0, blue: 0xE6 / 255.0, alpha: 1)
            : UIColor(red: 0x5B / 255.0, green: 0x54 / 255.0, blue: 0xC9 / 255.0, alpha: 1)
    }
}
