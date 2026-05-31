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
}
