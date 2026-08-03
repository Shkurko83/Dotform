import SwiftUI
import WatchConnectivity

@main
struct DotformWatchApp: App {
    @StateObject private var bridge = WatchRelayReceiver()

    var body: some Scene {
        WindowGroup {
            WatchRelayView()
                .environmentObject(bridge)
        }
    }
}
