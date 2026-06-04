import MapKit
import UIKit

final class MMLTileOverlay: MKTileOverlay, @unchecked Sendable {
    let apiKey: String
    private let layer: String
    private let tileMatrixSet: String
    private let cache: TileCache

    private static let maxMML = 15

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
        maximumZ = 18
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
        let maxZ = Self.maxMML

        if path.z <= maxZ {
            fetchOrCache(path: path, result: result)
            return
        }

        // Beyond MML's max zoom: fetch the z=15 ancestor, crop the right
        // sub-region, and scale it to 256×256 so MapKit sees a proper tile.
        let shift = path.z - maxZ
        let ancestor = MKTileOverlayPath(
            x: path.x >> shift, y: path.y >> shift, z: maxZ,
            contentScaleFactor: path.contentScaleFactor
        )
        let subX = path.x - (ancestor.x << shift)
        let subY = path.y - (ancestor.y << shift)

        fetchOrCache(path: ancestor) { data, error in
            guard let data else { result(nil, error); return }
            result(Self.cropAndScale(data: data, subX: subX, subY: subY, shift: shift), nil)
        }
    }

    // MARK: - Helpers

    private func fetchOrCache(path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let key = "\(layer)/\(path.z)/\(path.y)/\(path.x)"
        if let cached = cache.data(forKey: key) {
            result(cached, nil)
            return
        }
        let url = tileURL(for: path)
        URLSession.shared.dataTask(with: url) { [cache] data, _, error in
            if let data { cache.store(data, forKey: key) }
            result(data, error)
        }.resume()
    }

    // Crops the sub-tile at (subX, subY) within the parent tile grid (2^shift divisions)
    // and scales the result to 256×256.
    //
    // Drawing trick: render the parent image at scale `divisor` (so it fills
    // divisor×256 pixels) then offset so the desired sub-region lands at origin.
    // The 256×256 renderer naturally clips everything outside.
    private static func cropAndScale(data: Data, subX: Int, subY: Int, shift: Int) -> Data? {
        guard let source = UIImage(data: data) else { return nil }
        let divisor = CGFloat(1 << shift)
        let size = CGSize(width: 256, height: 256)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            source.draw(in: CGRect(
                x: -CGFloat(subX) * 256,
                y: -CGFloat(subY) * 256,
                width: 256 * divisor,
                height: 256 * divisor
            ))
        }
        return image.pngData()
    }
}
