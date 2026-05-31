import Testing
import Foundation
import SwiftData
@testable import Fisu

@Suite @MainActor struct CatchStoreTests {
    func makeStore() throws -> CatchStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Catch.self, Trip.self, configurations: config)
        return CatchStore(context: container.mainContext)
    }

    @Test func createCatchSavesSpeciesAndCoord() throws {
        let store = try makeStore()
        let entry = store.create(speciesCode: "hauki", latitude: 61.0, longitude: 25.0)
        #expect(entry.speciesCode == "hauki")
        #expect(entry.latitude == 61.0)
    }

    @Test func personalBestByWeight() throws {
        let store = try makeStore()
        store.create(speciesCode: "hauki", latitude: 0, longitude: 0, weightGram: 2000)
        store.create(speciesCode: "hauki", latitude: 0, longitude: 0, weightGram: 3500)
        let bests = try store.personalBests()
        #expect(bests["hauki"]?.weightGram == 3500)
    }

    @Test func personalBestFallsBackToLength() throws {
        let store = try makeStore()
        store.create(speciesCode: "ahven", latitude: 0, longitude: 0, lengthMm: 240)
        store.create(speciesCode: "ahven", latitude: 0, longitude: 0, lengthMm: 310)
        let bests = try store.personalBests()
        #expect(bests["ahven"]?.lengthMm == 310)
    }

    @Test func filterBySpecies() throws {
        let store = try makeStore()
        store.create(speciesCode: "hauki", latitude: 0, longitude: 0)
        store.create(speciesCode: "ahven", latitude: 0, longitude: 0)
        store.create(speciesCode: "hauki", latitude: 0, longitude: 0)
        let results = try store.catches(filter: CatchFilter(species: ["hauki"]))
        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.speciesCode == "hauki" })
    }

    @Test func filterByDateRange() throws {
        let store = try makeStore()
        let old = Date(timeIntervalSinceNow: -86400 * 10)
        let recent = Date(timeIntervalSinceNow: -3600)
        store.create(speciesCode: "hauki", latitude: 0, longitude: 0, timestamp: old)
        store.create(speciesCode: "ahven", latitude: 0, longitude: 0, timestamp: recent)
        let range = Date(timeIntervalSinceNow: -86400 * 5)...Date.now
        let results = try store.catches(filter: CatchFilter(dateRange: range))
        #expect(results.count == 1)
        #expect(results[0].speciesCode == "ahven")
    }

    @Test func sortBiggestFirst() throws {
        let store = try makeStore()
        store.create(speciesCode: "hauki", latitude: 0, longitude: 0, weightGram: 2000)
        store.create(speciesCode: "ahven", latitude: 0, longitude: 0, weightGram: 500)
        store.create(speciesCode: "kuha",  latitude: 0, longitude: 0, weightGram: 1200)
        let results = try store.catches(filter: CatchFilter(sortOrder: .biggestFirst))
        #expect(results[0].weightGram == 2000)
        #expect(results[1].weightGram == 1200)
        #expect(results[2].weightGram == 500)
    }

    @Test func deleteCatch() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Catch.self, Trip.self, configurations: config)
        let store = CatchStore(context: container.mainContext)
        let entry = store.create(speciesCode: "hauki", latitude: 0, longitude: 0)
        store.delete(entry)
        let all = try container.mainContext.fetch(FetchDescriptor<Catch>())
        #expect(all.isEmpty)
    }
}
