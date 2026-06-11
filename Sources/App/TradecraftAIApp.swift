import SwiftUI
import SwiftData

@main
struct TradecraftAIApp: App {
    @StateObject private var sub = SubscriptionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sub)
        }
        .modelContainer(for: JobRecord.self)
    }
}
