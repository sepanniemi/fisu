import Foundation

struct RoutePoint: Codable, Sendable {
    let lat: Double
    let lon: Double
    let t: Date
    let speed: Double?
}
