import Testing
import Foundation
import SwiftData
@testable import Fisu

@Suite struct CatchStoreTests {
    // makeStore() returns the container alongside the store.
    // Each test must hold the container in a local variable for its entire body —
    // if the container is released early, SwiftData may tear down the SQLite store
    // while the context is still in use, causing an EXC_BAD_INSTRUCTION trap.
    @MainActor func makeStore() throws -> (ModelContainer, CatchStore) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: Catch.self, Trip.self, configurations: config)
        return (container, CatchStore(context: container.mainContext))
    }

    @Test @MainActor func createCatchSavesSpeciesAndCoord() throws {
        let (container, store) = try makeStore()
        let entry = store.create(speciesCode: "hauki", latitude: 61.0, longitude: 25.0)
        #expect(entry.speciesCode == "hauki")
        #expect(entry.latitude == 61.0)
        withExtendedLifetime(container) {}
    }

    @Test @MainActor func personalBestByWeight() throws {
        let (container, store) = try makeStore()
        store.create(speciesCode: "hauki", latitude: 0, longitude: 0, weightGram: 2000)
        store.create(speciesCode: "hauki", latitude: 0, longitude: 0, weightGram: 3500)
        let bests = try store.personalBests()
        #expect(bests["hauki"]?.weightGram == 3500)
        withExtendedLifetime(container) {}
    }

    @Test @MainActor func personalBestFallsBackToLength() throws {
        let (container, store) = try makeStore()
        store.create(speciesCode: "ahven", latitude: 0, longitude: 0, lengthMm: 240)
        store.create(speciesCode: "ahven", latitude: 0, longitude: 0, lengthMm: 310)
        let bests = try store.personalBests()
        #expect(bests["ahven"]?.lengthMm == 310)
        withExtendedLifetime(container) {}
    }

    @Test @MainActor func filterBySpecies() throws {
        let (container, store) = try makeStore()
        store.create(speciesCode: "hauki", latitude: 0, longitude: 0)
        store.create(speciesCode: "ahven", latitude: 0, longitude: 0)
        store.create(speciesCode: "hauki", latitude: 0, longitude: 0)
        let results = try store.catches(filter: CatchFilter(species: ["hauki"]))
        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.speciesCode == "hauki" })
        withExtendedLifetime(container) {}
    }

    @Test @MainActor func filterByDateRange() throws {
        let (container, store) = try makeStore()
        let old = Date(timeIntervalSinceNow: -86400 * 10)
        let recent = Date(timeIntervalSinceNow: -3600)
        store.create(speciesCode: "hauki", latitude: 0, longitude: 0, timestamp: old)
        store.create(speciesCode: "ahven", latitude: 0, longitude: 0, timestamp: recent)
        let range = Date(timeIntervalSinceNow: -86400 * 5)...Date.now
        let results = try store.catches(filter: CatchFilter(dateRange: range))
        #expect(results.count == 1)
        #expect(results[0].speciesCode == "ahven")
        withExtendedLifetime(container) {}
    }

    @Test @MainActor func sortBiggestFirst() throws {
        let (container, store) = try makeStore()
        store.create(speciesCode: "hauki", latitude: 0, longitude: 0, weightGram: 2000)
        store.create(speciesCode: "ahven", latitude: 0, longitude: 0, weightGram: 500)
        store.create(speciesCode: "kuha",  latitude: 0, longitude: 0, weightGram: 1200)
        let results = try store.catches(filter: CatchFilter(sortOrder: .biggestFirst))
        #expect(results[0].weightGram == 2000)
        #expect(results[1].weightGram == 1200)
        #expect(results[2].weightGram == 500)
        withExtendedLifetime(container) {}
    }

    @Test @MainActor func deleteCatch() throws {
        let (container, store) = try makeStore()
        let entry = store.create(speciesCode: "hauki", latitude: 0, longitude: 0)
        store.delete(entry)
        let all = try container.mainContext.fetch(FetchDescriptor<Catch>())
        #expect(all.isEmpty)
        withExtendedLifetime(container) {}
    }
}
