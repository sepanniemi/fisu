import CoreLocation
import SwiftData
import Observation

// Internal free function — not namespaced so TripRecorderTests can call it directly.
func haversineMeters(from a: RoutePoint, to b: RoutePoint) -> Double {
    let R = 6_371_000.0
    let lat1 = a.lat * .pi / 180, lat2 = b.lat * .pi / 180
    let dLat = (b.lat - a.lat) * .pi / 180
    let dLon = (b.lon - a.lon) * .pi / 180
    let sinDLat = sin(dLat / 2), sinDLon = sin(dLon / 2)
    let h = sinDLat * sinDLat + cos(lat1) * cos(lat2) * sinDLon * sinDLon
    return R * 2 * atan2(sqrt(h), sqrt(1 - h))
}

enum TripState { case idle, recording, paused }

@Observable @MainActor
final class TripRecorder {
    private(set) var state: TripState = .idle
    private(set) var activeTrip: Trip?
    private(set) var routePoints: [RoutePoint] = []
    private(set) var distanceMeters: Double = 0
    private(set) var startTime: Date?

    private let locationService: LocationService
    private let context: ModelContext

    init(locationService: LocationService, context: ModelContext) {
        self.locationService = locationService
        self.context = context
    }

    func start() {
        guard state == .idle else { return }
        let trip = Trip()
        trip.startTime = .now
        trip.title = Self.autoTitle(for: .now)
        context.insert(trip)
        activeTrip = trip
        routePoints = []
        distanceMeters = 0
        startTime = .now
        state = .recording
        locationService.requestAlways()
        locationService.startUpdating()
    }

    func pause() {
        guard state == .recording else { return }
        state = .paused
        locationService.stopUpdating()
    }

    func resume() {
        guard state == .paused else { return }
        state = .recording
        locationService.startUpdating()
    }

    func stop() {
        guard state != .idle, let trip = activeTrip else { return }
        locationService.stopUpdating()
        trip.endTime = .now
        trip.routeData = try? JSONEncoder().encode(routePoints)
        trip.distanceMeters = distanceMeters
        state = .idle
        activeTrip = nil
        startTime = nil
    }

    func appendLocation(_ location: CLLocation) {
        guard state == .recording else { return }
        let point = RoutePoint(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude,
            t: location.timestamp,
            speed: location.speed >= 0 ? location.speed : nil
        )
        if let last = routePoints.last {
            distanceMeters += haversineMeters(from: last, to: point)
        }
        routePoints.append(point)
    }

    var duration: TimeInterval {
        guard let start = startTime else { return 0 }
        return Date.now.timeIntervalSince(start)
    }

    var durationFormatted: String {
        let total = Int(duration)
        return String(format: "%d:%02d", total / 3600, (total % 3600) / 60)
    }

    var distanceKmFormatted: String {
        String(format: "%.1f km", distanceMeters / 1000)
    }

    private static func autoTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fi_FI")
        f.dateFormat = "d.M."
        return "\(f.string(from: date)) troolaus"
    }
}
