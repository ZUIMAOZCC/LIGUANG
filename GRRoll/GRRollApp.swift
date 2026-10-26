import SwiftUI

@main
struct GRRollApp: App {
    @StateObject private var subscription = SubscriptionManager.shared
    @StateObject private var presetStore = PresetStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(subscription)
                .environmentObject(presetStore)
        }
    }
}
