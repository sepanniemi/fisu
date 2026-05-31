import Testing
import Foundation
@testable import Fisu

@Suite struct RouteTests {
    @Test func encodeDecodeRoundtrip() throws {
        let points = [
            RoutePoint(lat: 61.4978, lon: 23.7610, t: Date(timeIntervalSince1970: 1_000_000), speed: 1.5),
            RoutePoint(lat: 61.4990, lon: 23.7630, t: Date(timeIntervalSince1970: 1_000_060), speed: 1.6),
        ]
        let data = try JSONEncoder().encode(points)
        let decoded = try JSONDecoder().decode([RoutePoint].self, from: data)
        #expect(decoded.count == 2)
        #expect(decoded[0].lat == 61.4978)
        #expect(decoded[1].speed == 1.6)
    }
}
