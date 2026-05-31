import SwiftUI
import MapKit

struct MapContainerView: UIViewRepresentable {
    let catches: [Catch]
    let displayMode: CatchDisplayMode
    let routePoints: [RoutePoint]
    let apiKey: String
    let onCatchSelected: (Catch) -> Void
    let onCatchDeselected: () -> Void

    func makeCoordinator() -> MapCoordinator {
        MapCoordinator(onCatchSelected: onCatchSelected, onCatchDeselected: onCatchDeselected)
    }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.showsCompass = true
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        map.isRotateEnabled = true
        map.isPitchEnabled = false

        map.register(CatchAnnotationView.self, forAnnotationViewWithReuseIdentifier: CatchAnnotationView.reuseId)
        map.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)

        let finland = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 64.5, longitude: 26.0),
            span: MKCoordinateSpan(latitudeDelta: 12, longitudeDelta: 12)
        )
        map.setRegion(finland, animated: false)

        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        syncOverlay(map)
        context.coordinator.syncAnnotations(mapView: map, catches: catches, displayMode: displayMode)
        context.coordinator.syncRoute(mapView: map, routePoints: routePoints)
    }

    // Adds the MML tile overlay when a key is available; removes it when the key is cleared.
    // Called on every updateUIView so Settings changes take effect without restarting.
    private func syncOverlay(_ map: MKMapView) {
        let existing = map.overlays.compactMap { $0 as? MMLTileOverlay }
        if apiKey.isEmpty {
            map.removeOverlays(existing)
            return
        }
        // Already present with the same key — nothing to do.
        if existing.first?.apiKey == apiKey { return }
        // Remove stale overlay (key changed) then add fresh one.
        map.removeOverlays(existing)
        let cacheDir = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("mml_tiles")
        let overlay = MMLTileOverlay(apiKey: apiKey, cache: TileCache(directory: cacheDir))
        // .aboveRoads is correct for canReplaceMapContent = true so MapKit suppresses its own tiles.
        map.addOverlay(overlay, level: .aboveRoads)
    }
}
