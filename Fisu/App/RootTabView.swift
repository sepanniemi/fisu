import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                MapScreen()
            }
            .tabItem { Label("Map", systemImage: "map.fill") }

            CatchesListView()
                .tabItem { Label("Catches", systemImage: "fish.fill") }

            TripsListView()
                .tabItem { Label("Trips", systemImage: "point.topleft.down.to.point.bottomright.curvepath.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
