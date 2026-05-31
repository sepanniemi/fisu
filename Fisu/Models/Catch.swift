import SwiftData
import Foundation

@Model final class Catch {
    var id: UUID = UUID()
    var timestamp: Date = Date.now
    var latitude: Double = 0
    var longitude: Double = 0
    var horizontalAccuracy: Double?
    var speciesCode: String?
    var speciesCustomName: String?
    var lengthMm: Int?
    var weightGram: Int?
    var released: Bool?
    var lure: String?
    var method: String?
    var notes: String?
    @Attribute(.externalStorage) var photoData: Data?
    @Attribute(.externalStorage) var thumbnailData: Data?
    var trip: Trip?

    init() {}
}
