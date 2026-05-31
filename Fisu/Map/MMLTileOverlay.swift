import MapKit

final class MMLTileOverlay: MKTileOverlay, @unchecked Sendable {
    let apiKey: String
    private let layer: String
    private let tileMatrixSet: String
    private let cache: TileCache

    init(
        apiKey: String,
        layer: String = "maastokartta",
        tileMatrixSet: String = "WGS84_Pseudo-Mercator",
        cache: TileCache
    ) {
        self.apiKey = apiKey
        self.layer = layer
        self.tileMatrixSet = tileMatrixSet
        self.cache = cache
        super.init(urlTemplate: nil)
        canReplaceMapContent = false   // overlay on top; full replacement caused blank map on tile errors
        minimumZ = 0
        maximumZ = 15
        tileSize = CGSize(width: 256, height: 256)
    }

    // Exposed for testing; builds the MML WMTS RESTful URL.
    // MML path order: .../TileMatrix/TileRow/TileCol.png
    // MapKit: z = TileMatrix, y = TileRow, x = TileCol
    func tileURL(for path: MKTileOverlayPath) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "avoin-karttakuva.maanmittauslaitos.fi"
        components.path = "/avoin/wmts/1.0.0/\(layer)/default/\(tileMatrixSet)/\(path.z)/\(path.y)/\(path.x).png"
        components.queryItems = [URLQueryItem(name: "api-key", value: apiKey)]
        return components.url!
    }

    override func loadTile(
        at path: MKTileOverlayPath,
        result: @escaping (Data?, Error?) -> Void
    ) {
        // Key mirrors URL path order: z/y/x (TileMatrix/TileRow/TileCol)
        let key = "\(layer)/\(path.z)/\(path.y)/\(path.x)"
        if let cached = cache.data(forKey: key) {
            result(cached, nil)
            return
        }
        let url = tileURL(for: path)
        URLSession.shared.dataTask(with: url) { [cache] data, _, error in
            if let data {
                cache.store(data, forKey: key)
            }
            result(data, error)
        }.resume()
    }
}
