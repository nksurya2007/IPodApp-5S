import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private let vc = iPodViewController()

    /// true = fully quit the app (and stop the music) as soon as it leaves the screen.
    private let quitWhenClosed = true

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        var task = UIBackgroundTaskIdentifier.invalid
        task = application.beginBackgroundTask { application.endBackgroundTask(task) }
        vc.shutdown()
        if quitWhenClosed {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
        } else {
            application.endBackgroundTask(task)
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        vc.shutdown()
    }
}
