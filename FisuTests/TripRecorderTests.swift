import Testing
import CoreLocation
@testable import Fisu

@Suite struct TripRecorderTests {
    // Haversine: Helsinki (60.1699, 24.9384) → Tampere (61.4978, 23.7610) ≈ 166 km
    @Test func haversineApproximation() {
        let p1 = RoutePoint(lat: 60.1699, lon: 24.9384, t: .now, speed: nil)
        let p2 = RoutePoint(lat: 61.4978, lon: 23.7610, t: .now, speed: nil)
        let dist = haversineMeters(from: p1, to: p2)
        #expect(dist > 155_000 && dist < 180_000)
    }

    @Test func zeroDistanceForSinglePoint() {
        let p = RoutePoint(lat: 61.0, lon: 25.0, t: .now, speed: nil)
        let dist = haversineMeters(from: p, to: p)
        #expect(dist < 1)
    }
}
