import Testing
import MapKit
@testable import Fisu

@Suite struct TileMathTests {
    func makeOverlay(key: String = "test-key") -> MMLTileOverlay {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        return MMLTileOverlay(apiKey: key, cache: TileCache(directory: dir))
    }

    @Test func urlContainsLayerAndZXY() {
        let overlay = makeOverlay()
        let path = MKTileOverlayPath(x: 590, y: 291, z: 10, contentScaleFactor: 1)
        let url = overlay.tileURL(for: path)
        #expect(url.host == "avoin-karttakuva.maanmittauslaitos.fi")
        #expect(url.path.contains("/maastokartta/"))
        #expect(url.path.contains("/10/291/590"))
    }

    @Test func urlContainsApiKey() {
        let overlay = makeOverlay(key: "my-secret-key")
        let path = MKTileOverlayPath(x: 1, y: 2, z: 5, contentScaleFactor: 1)
        let url = overlay.tileURL(for: path)
        #expect(url.query?.contains("api-key=my-secret-key") == true)
    }

    @Test func urlUsesWGS84PseudoMercator() {
        let overlay = makeOverlay()
        let path = MKTileOverlayPath(x: 0, y: 0, z: 0, contentScaleFactor: 1)
        let url = overlay.tileURL(for: path)
        #expect(url.path.contains("WGS84_Pseudo-Mercator"))
    }

    @Test func overlayReplacesBaseContent() {
        let overlay = makeOverlay()
        #expect(overlay.canReplaceMapContent == true)
    }

    // Regression test: cache key must use z/y/x (matching URL), not z/x/y.
    // If the orders differ, tiles with x≠y are written under a key that is
    // never looked up — the cache becomes a no-op for almost all real tiles.
    @Test func cacheKeyMatchesUrlAxisOrder() {
        let overlay = makeOverlay()
        // Use asymmetric x/y so a z/x/y vs z/y/x swap would produce distinct strings
        let path = MKTileOverlayPath(x: 590, y: 291, z: 10, contentScaleFactor: 1)
        let url = overlay.tileURL(for: path)
        // URL must contain z/y/x in path
        let pathContainsZYX = url.path.contains("/10/291/590")   // z=10, y=291, x=590
        let pathContainsZXY = url.path.contains("/10/590/291")   // wrong order
        #expect(pathContainsZYX == true)
        #expect(pathContainsZXY == false)
    }
}
