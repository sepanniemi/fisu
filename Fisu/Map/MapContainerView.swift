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

        // If a key is already available at launch, install the overlay immediately.
        if !apiKey.isEmpty {
            map.addOverlay(mmlOverlay(for: apiKey), level: .aboveLabels)
            print("[Fisu] MML overlay added at makeUIView, key prefix: \(apiKey.prefix(6))…")
        }

        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        syncOverlay(map)
        context.coordinator.syncAnnotations(mapView: map, catches: catches, displayMode: displayMode)
        // After syncOverlay, so the route is appended above the tile overlay.
        context.coordinator.syncRoute(mapView: map, routePoints: routePoints)
    }

    private func mmlOverlay(for key: String) -> MMLTileOverlay {
        let cacheDir = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("mml_tiles")
        return MMLTileOverlay(apiKey: key, cache: TileCache(directory: cacheDir))
    }

    private func syncOverlay(_ map: MKMapView) {
        let existing = map.overlays.compactMap { $0 as? MMLTileOverlay }

        if apiKey.isEmpty {
            if !existing.isEmpty {
                map.removeOverlays(existing)
                print("[Fisu] MML overlay removed (key cleared)")
            }
            return
        }

        if existing.first?.apiKey == apiKey {
            return  // already installed with the right key
        }

        map.removeOverlays(existing)
        map.addOverlay(mmlOverlay(for: apiKey), level: .aboveLabels)
        print("[Fisu] MML overlay added/updated in updateUIView, key prefix: \(apiKey.prefix(6))…")
    }
}
