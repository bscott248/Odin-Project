import SwiftUI
import SwiftData

@main
struct CampmarkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [CampingTrip.self, CampingSetup.self])
    }
}
