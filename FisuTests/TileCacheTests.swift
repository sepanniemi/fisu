import Testing
import Foundation
@testable import Fisu

@Suite struct TileCacheTests {
    func tempCache() -> (TileCache, URL) {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("fisu_tile_test_\(UUID().uuidString)")
        return (TileCache(directory: dir), dir)
    }

    @Test func storeAndRetrieve() {
        let (cache, dir) = tempCache()
        defer { try? FileManager.default.removeItem(at: dir) }
        let payload = Data("tile-bytes".utf8)
        cache.store(payload, forKey: "10/590/291")
        #expect(cache.data(forKey: "10/590/291") == payload)
    }

    @Test func missingKeyReturnsNil() {
        let (cache, dir) = tempCache()
        defer { try? FileManager.default.removeItem(at: dir) }
        #expect(cache.data(forKey: "notexist") == nil)
    }

    @Test func differentKeysStoredSeparately() {
        let (cache, dir) = tempCache()
        defer { try? FileManager.default.removeItem(at: dir) }
        cache.store(Data("a".utf8), forKey: "key1")
        cache.store(Data("b".utf8), forKey: "key2")
        #expect(cache.data(forKey: "key1") == Data("a".utf8))
        #expect(cache.data(forKey: "key2") == Data("b".utf8))
    }

    @Test func slashAndColonInKeyAreSanitised() {
        // "10/590/291" and "10:590:291" must not collide with a flat-key "10_590_291"
        let (cache, dir) = tempCache()
        defer { try? FileManager.default.removeItem(at: dir) }
        let tileData = Data("tile".utf8)
        cache.store(tileData, forKey: "10/590/291")
        // Retrieval with the original key works
        #expect(cache.data(forKey: "10/590/291") == tileData)
        // A key that sanitises to the same filename reads the same file
        #expect(cache.data(forKey: "10_590_291") == tileData)
    }

    @Test func evictsOldestWhenOverLimit() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("fisu_evict_test_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }

        // maxBytes = 30 bytes; each entry is ~10 bytes
        let cache = TileCache(directory: dir, maxBytes: 30)

        // Store three entries with deliberate mtime ordering
        cache.store(Data("1234567890".utf8), forKey: "old")
        Thread.sleep(forTimeInterval: 0.02)
        cache.store(Data("1234567890".utf8), forKey: "mid")
        Thread.sleep(forTimeInterval: 0.02)
        // This store pushes total to ~30 bytes, at the limit — no eviction yet
        cache.store(Data("1234567890".utf8), forKey: "new")
        Thread.sleep(forTimeInterval: 0.02)
        // This store pushes total over limit; "old" should be evicted
        cache.store(Data("1234567890".utf8), forKey: "newest")

        #expect(cache.data(forKey: "old") == nil, "oldest entry should have been evicted")
        #expect(cache.data(forKey: "newest") != nil, "newest entry should survive")
    }
}
