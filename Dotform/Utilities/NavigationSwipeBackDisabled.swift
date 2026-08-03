import UIKit

extension UINavigationController {
    func setSwipeBackEnabled(_ enabled: Bool) {
        interactivePopGestureRecognizer?.isEnabled = enabled
        if #available(iOS 26.0, *) {
            interactiveContentPopGestureRecognizer?.isEnabled = enabled
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        NavigationSwipeBackManager.shared.disableInKeyWindow()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NavigationSwipeBackManager.shared.disableInKeyWindow()
    }
}
