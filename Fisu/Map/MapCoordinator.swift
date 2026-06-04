import MapKit
import UIKit

@MainActor
final class MapCoordinator: NSObject, MKMapViewDelegate {
    var onCatchSelected: (Catch) -> Void
    var onCatchDeselected: () -> Void
    var displayMode: CatchDisplayMode = .dots
    var hasInitiallyCentered = false

    init(onCatchSelected: @escaping (Catch) -> Void, onCatchDeselected: @escaping () -> Void) {
        self.onCatchSelected = onCatchSelected
        self.onCatchDeselected = onCatchDeselected
    }

    func syncAnnotations(mapView: MKMapView, catches: [Catch], displayMode: CatchDisplayMode) {
        self.displayMode = displayMode

        if displayMode == .hidden {
            let toRemove = mapView.annotations.filter { $0 is CatchAnnotation || $0 is MKClusterAnnotation }
            mapView.removeAnnotations(toRemove)
            return
        }

        let existing = mapView.annotations.compactMap { $0 as? CatchAnnotation }
        let existingIds = Set(existing.map { ObjectIdentifier($0.entry) })
        let newIds = Set(catches.map { ObjectIdentifier($0) })

        let toRemove = existing.filter { !newIds.contains(ObjectIdentifier($0.entry)) }
        mapView.removeAnnotations(toRemove)

        let toAdd = catches.filter { !existingIds.contains(ObjectIdentifier($0)) }
            .map { CatchAnnotation(entry: $0) }
        mapView.addAnnotations(toAdd)

        for ann in mapView.annotations.compactMap({ $0 as? CatchAnnotation }) {
            (mapView.view(for: ann) as? CatchAnnotationView)?.displayMode = displayMode
        }
    }

    func syncRoute(mapView: MKMapView, routePoints: [RoutePoint]) {
        mapView.overlays.filter { $0 is MKPolyline }.forEach { mapView.removeOverlay($0) }
        guard routePoints.count >= 2 else { return }
        let coords = routePoints.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) }
        mapView.addOverlay(MKPolyline(coordinates: coords, count: coords.count), level: .aboveRoads)
    }

    // MARK: MKMapViewDelegate

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKTileOverlay {
            return MKTileOverlayRenderer(overlay: overlay)
        }
        if let polyline = overlay as? MKPolyline {
            let r = MKPolylineRenderer(polyline: polyline)
            r.strokeColor = UIColor(red: 0.12, green: 0.48, blue: 0.88, alpha: 0.9)
            r.lineWidth = 3.5
            return r
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }

        if annotation is CatchAnnotation {
            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: CatchAnnotationView.reuseId, for: annotation
            ) as! CatchAnnotationView
            view.displayMode = displayMode
            return view
        }

        if annotation is MKClusterAnnotation {
            return mapView.dequeueReusableAnnotationView(
                withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier,
                for: annotation
            ) as! ClusterAnnotationView
        }

        return nil
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard !hasInitiallyCentered, let loc = userLocation.location else { return }
        let region = MKCoordinateRegion(
            center: loc.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapView.setRegion(region, animated: true)
        hasInitiallyCentered = true
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let v = view as? CatchAnnotationView,
           let ann = v.annotation as? CatchAnnotation {
            onCatchSelected(ann.entry)
        }
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if view is CatchAnnotationView { onCatchDeselected() }
    }
}
