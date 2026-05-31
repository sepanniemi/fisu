import SwiftData
import Foundation

@Model final class Catch {
    // Display/export identifier only — use PersistentIdentifier for SwiftData lookups.
    var id: UUID = UUID()
    var timestamp: Date = Date.now
    var latitude: Double = 0
    var longitude: Double = 0
    var horizontalAccuracy: Double?
    var speciesCode: String?
    var speciesCustomName: String?
    var lengthMm: Int?
    var weightGram: Int?
    var released: Bool?   // nil = unsaid, false = kept, true = released
    var lure: String?
    var method: String?
    var notes: String?
    @Attribute(.externalStorage) var photoData: Data?
    var thumbnailData: Data?   // stored inline (~5–15 KB) for fast list scrolling
    var trip: Trip?

    init() {}
}
