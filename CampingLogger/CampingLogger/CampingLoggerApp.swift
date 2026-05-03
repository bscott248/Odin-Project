import SwiftUI
import SwiftData

@main
struct CampingLoggerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [CampingTrip.self, CampingSetup.self])
    }
}
