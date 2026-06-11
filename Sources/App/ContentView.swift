import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var sub: SubscriptionManager
    @State private var showSettings = false
    @State private var showPaywall = false

    var body: some View {
        TabView {
            PhotoDiagnosisView()
                .tabItem { Label("Diagnose", systemImage: "camera.fill") }
            SmartQuoteView()
                .tabItem { Label("Quote", systemImage: "doc.text.fill") }
            VoiceRecordView()
                .tabItem { Label("Voice", systemImage: "mic.fill") }
            CustomerBotView()
                .tabItem { Label("Bot", systemImage: "message.fill") }
            TroubleshootView()
                .tabItem { Label("Help", systemImage: "wrench.and.screwdriver.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
        }
        .tint(.orange)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .fullScreenCover(isPresented: $showPaywall) { PaywallView() }
        .onAppear { checkOnboarding() }
        .onChange(of: sub.isSubscribed) { _, subscribed in
            if subscribed { showPaywall = false }
        }
    }

    private func checkOnboarding() {
        if Config.openAIKey.isEmpty {
            showSettings = true
        } else if !sub.isSubscribed {
            showPaywall = true
        }
    }
}
