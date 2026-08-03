import SwiftUI
import UIKit

/// Оформление полноэкранных карточек: без tab bar, без свайпа назад, контент под navigation bar.
struct CardScreenChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .tabBar)
            .background(SwipeBackDisablerHost())
            .onAppear { NavigationSwipeBackManager.shared.disableInKeyWindow() }
            .onDisappear { NavigationSwipeBackManager.shared.disableInKeyWindow() }
    }
}

extension View {
    func cardScreenChrome() -> some View {
        modifier(CardScreenChrome())
    }
}

private struct SwipeBackDisablerHost: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SwipeBackDisablerViewController {
        SwipeBackDisablerViewController()
    }

    func updateUIViewController(_ uiViewController: SwipeBackDisablerViewController, context: Context) {
        uiViewController.disableSwipeBack()
    }
}

private final class SwipeBackDisablerViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        disableSwipeBack()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disableSwipeBack()
        scheduleRepeatedDisable()
    }

    func disableSwipeBack() {
        if let navigationController = findNavigationController() {
            NavigationSwipeBackManager.shared.apply(to: navigationController)
        } else {
            NavigationSwipeBackManager.shared.disableInKeyWindow()
        }
    }

    private func scheduleRepeatedDisable() {
        for delay in [0.05, 0.15, 0.35] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.disableSwipeBack()
            }
        }
    }

    private func findNavigationController() -> UINavigationController? {
        var current: UIViewController? = self
        while let viewController = current {
            if let navigationController = viewController.navigationController {
                return navigationController
            }
            current = viewController.parent
        }
        return nil
    }
}

@MainActor
final class NavigationSwipeBackManager {
    static let shared = NavigationSwipeBackManager()

    private let popBlocker = PopGestureBlocker()

    func disableInKeyWindow() {
        guard let root = keyWindowRootViewController() else { return }
        disableSwipeBack(in: root)
    }

    func apply(to navigationController: UINavigationController) {
        navigationController.setSwipeBackEnabled(false)
        navigationController.interactivePopGestureRecognizer?.delegate = popBlocker
        if #available(iOS 26.0, *) {
            navigationController.interactiveContentPopGestureRecognizer?.delegate = popBlocker
        }
    }

    private func keyWindowRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }

    private func disableSwipeBack(in viewController: UIViewController) {
        if let navigationController = viewController as? UINavigationController {
            apply(to: navigationController)
        }

        if let navigationController = viewController.navigationController {
            apply(to: navigationController)
        }

        viewController.children.forEach { disableSwipeBack(in: $0) }

        if let presented = viewController.presentedViewController {
            disableSwipeBack(in: presented)
        }
    }
}

private final class PopGestureBlocker: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
}
