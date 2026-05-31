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
        map.isRotateEnabled = true
        map.isPitchEnabled = false

        if !apiKey.isEmpty {
            let cacheDir = FileManager.default
                .urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("mml_tiles")
            let overlay = MMLTileOverlay(apiKey: apiKey, cache: TileCache(directory: cacheDir))
            map.addOverlay(overlay, level: .aboveLabels)
        }

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
        context.coordinator.syncAnnotations(mapView: map, catches: catches, displayMode: displayMode)
        context.coordinator.syncRoute(mapView: map, routePoints: routePoints)
    }
}
