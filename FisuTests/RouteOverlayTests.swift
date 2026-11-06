import Testing
import Foundation
import MapKit
@testable import Fisu

/// `MapCoordinator.syncRoute` turns the recorded `RoutePoint`s into the polyline drawn on the map.
@Suite struct RouteOverlayTests {
    // A short zig-zag across a lake near Tampere.
    private static let route = [
        RoutePoint(lat: 61.4978, lon: 23.7610, t: Date(timeIntervalSince1970: 1_000_000), speed: 1.2),
        RoutePoint(lat: 61.4990, lon: 23.7650, t: Date(timeIntervalSince1970: 1_000_060), speed: 1.4),
        RoutePoint(lat: 61.4985, lon: 23.7700, t: Date(timeIntervalSince1970: 1_000_120), speed: 1.3),
        RoutePoint(lat: 61.5002, lon: 23.7745, t: Date(timeIntervalSince1970: 1_000_180), speed: 1.5),
    ]

    // MARK: Stacking

    // Regression test: MapContainerView installs the MML topo tiles as an opaque overlay at
    // .aboveLabels, but the route was added at .aboveRoads, underneath the tiles. Once a tile
    // layer was showing, the trip route was never visible on the map.
    @Test @MainActor func routeIsDrawnAboveTheOpaqueMMLTiles() throws {
        let map = makeMap()
        let tiles = makeTiles()
        map.addOverlay(tiles, level: .aboveLabels)

        makeCoordinator().syncRoute(mapView: map, routePoints: Self.route)

        let polyline = try #require(routePolylines(on: map).first)
        #expect(
            isDrawn(polyline, above: tiles, on: map),
            "the route must be stacked above the tile overlay, otherwise the tiles cover it"
        )
    }

    // Changing the API key in Settings swaps in a fresh tile overlay (appended on top of the
    // route); MapContainerView then syncs the route again, which has to put it back on top.
    @Test @MainActor func routeStaysAboveTheTilesWhenTheApiKeyChanges() throws {
        let map = makeMap()
        let coordinator = makeCoordinator()
        let oldTiles = makeTiles(key: "old-key")
        map.addOverlay(oldTiles, level: .aboveLabels)
        coordinator.syncRoute(mapView: map, routePoints: Self.route)

        map.removeOverlay(oldTiles)
        let newTiles = makeTiles(key: "new-key")
        map.addOverlay(newTiles, level: .aboveLabels)
        coordinator.syncRoute(mapView: map, routePoints: Self.route)

        let polyline = try #require(routePolylines(on: map).first)
        #expect(isDrawn(polyline, above: newTiles, on: map))
    }

    // MARK: Route generation

    @Test @MainActor func polylineFollowsTheRecordedPoints() throws {
        let map = makeMap()

        makeCoordinator().syncRoute(mapView: map, routePoints: Self.route)

        let polyline = try #require(routePolylines(on: map).first)
        let drawn = coordinates(of: polyline)
        #expect(drawn.count == Self.route.count)
        for (coordinate, point) in zip(drawn, Self.route) {
            #expect(abs(coordinate.latitude - point.lat) < 1e-6)
            #expect(abs(coordinate.longitude - point.lon) < 1e-6)
        }
    }

    @Test @MainActor func fewerThanTwoPointsDrawNoRoute() {
        let map = makeMap()
        let coordinator = makeCoordinator()

        coordinator.syncRoute(mapView: map, routePoints: [])
        #expect(routePolylines(on: map).isEmpty)

        coordinator.syncRoute(mapView: map, routePoints: [Self.route[0]])
        #expect(routePolylines(on: map).isEmpty)
    }

    @Test @MainActor func newRouteReplacesThePreviousOne() {
        let map = makeMap()
        let coordinator = makeCoordinator()

        coordinator.syncRoute(mapView: map, routePoints: Array(Self.route.prefix(2)))
        coordinator.syncRoute(mapView: map, routePoints: Self.route)

        let polylines = routePolylines(on: map)
        #expect(polylines.count == 1)
        #expect(polylines.first?.pointCount == Self.route.count)
    }

    @Test @MainActor func startingANewTripClearsTheOldRoute() {
        let map = makeMap()
        let coordinator = makeCoordinator()
        coordinator.syncRoute(mapView: map, routePoints: Self.route)

        coordinator.syncRoute(mapView: map, routePoints: [])

        #expect(routePolylines(on: map).isEmpty)
    }

    // MARK: Helpers

    @MainActor private func makeMap() -> MKMapView {
        MKMapView(frame: CGRect(x: 0, y: 0, width: 360, height: 640))
    }

    @MainActor private func makeCoordinator() -> MapCoordinator {
        MapCoordinator(onCatchSelected: { _ in }, onCatchDeselected: {})
    }

    private func makeTiles(key: String = "test-key") -> MMLTileOverlay {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        return MMLTileOverlay(apiKey: key, cache: TileCache(directory: dir))
    }

    @MainActor private func routePolylines(on map: MKMapView) -> [MKPolyline] {
        map.overlays.compactMap { $0 as? MKPolyline }
    }

    @MainActor private func coordinates(of polyline: MKPolyline) -> [CLLocationCoordinate2D] {
        var result = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: polyline.pointCount)
        polyline.getCoordinates(&result, range: NSRange(location: 0, length: polyline.pointCount))
        return result
    }

    // MapKit draws .aboveLabels over .aboveRoads, and within one level later overlays over earlier ones.
    @MainActor private func isDrawn(_ upper: MKOverlay, above lower: MKOverlay, on map: MKMapView) -> Bool {
        guard let upperSlot = slot(of: upper, on: map), let lowerSlot = slot(of: lower, on: map) else {
            return false
        }
        if upperSlot.level != lowerSlot.level { return upperSlot.level > lowerSlot.level }
        return upperSlot.index > lowerSlot.index
    }

    @MainActor private func slot(of overlay: MKOverlay, on map: MKMapView) -> (level: Int, index: Int)? {
        for level in [MKOverlayLevel.aboveRoads, .aboveLabels] {
            if let index = map.overlays(in: level).firstIndex(where: { $0 === overlay }) {
                return (level.rawValue, index)
            }
        }
        return nil
    }
}
