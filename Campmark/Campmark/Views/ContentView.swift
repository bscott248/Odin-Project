import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TripListView()
                .tabItem {
                    Label("Trips", systemImage: "tent.fill")
                }

            SetupListView()
                .tabItem {
                    Label("Setups", systemImage: "backpack.fill")
                }
        }
    }
}
