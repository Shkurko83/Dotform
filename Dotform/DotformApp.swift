import SwiftUI

@main
struct DotformApp: App {
    init() {
        NavigationSwipeBackManager.shared.disableInKeyWindow()
        WatchConnectivityBridge.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
