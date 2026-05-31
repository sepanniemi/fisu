import MapKit

final class CatchAnnotation: NSObject, MKAnnotation {
    let entry: Catch

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: entry.latitude, longitude: entry.longitude)
    }

    var title: String? {
        FishSpeciesCatalog.displayName(for: entry.speciesCode)
    }

    init(entry: Catch) {
        self.entry = entry
        super.init()
    }
}
