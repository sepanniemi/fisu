import SwiftData
import Foundation

@Model final class Trip {
    var id: UUID = UUID()
    var title: String?
    var startTime: Date = Date.now
    var endTime: Date?
    @Attribute(.externalStorage) var routeData: Data?
    var distanceMeters: Double?
    @Relationship(deleteRule: .nullify, inverse: \Catch.trip) var catches: [Catch]?

    init() {}
}
