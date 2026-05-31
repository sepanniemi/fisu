import CoreLocation
import Observation

enum LocationError: Error {
    case noLocation
    case denied
}

@Observable @MainActor
final class LocationService: NSObject {
    private(set) var location: CLLocation?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5   // metres; reduces noise at trolling speeds
        authorizationStatus = manager.authorizationStatus
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlways() {
        manager.requestAlwaysAuthorization()
    }

    func startUpdating() {
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.allowsBackgroundLocationUpdates = false
        manager.stopUpdatingLocation()
    }

    var isAuthorizedForWhenInUse: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isAuthorizedAlways: Bool {
        authorizationStatus == .authorizedAlways
    }
}

extension LocationService: @preconcurrency CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor [weak self] in self?.location = loc }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in self?.authorizationStatus = status }
    }
}
