import SwiftUI
import AVFoundation

@main
struct TamreenApp: App {
    @StateObject private var store = Store()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Silent looping videos should not stop the user's music or podcasts.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar_SA@numbers=latn"))
                .onAppear { Reminders.requestAndSchedule(store) }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active { Reminders.schedule(store) }
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("اليوم", systemImage: "sun.max.fill") }
            ExercisesView()
                .tabItem { Label("التمارين", systemImage: "figure.walk") }
            ProgressGridView()
                .tabItem { Label("التقدّم", systemImage: "checkmark.seal.fill") }
            SettingsView()
                .tabItem { Label("الإعدادات", systemImage: "gearshape.fill") }
        }
        .tint(Color.figure)
    }
}
