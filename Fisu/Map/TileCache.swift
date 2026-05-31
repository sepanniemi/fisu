import Foundation

final class TileCache: @unchecked Sendable {
    private let directory: URL
    private let maxBytes: Int
    private let lock = NSLock()

    init(directory: URL, maxBytes: Int = 250 * 1024 * 1024) {
        self.directory = directory
        self.maxBytes = maxBytes
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func data(forKey key: String) -> Data? {
        let url = fileURL(for: key)
        lock.withLock {
            try? FileManager.default.setAttributes(
                [.modificationDate: Date()], ofItemAtPath: url.path
            )
        }
        return try? Data(contentsOf: url)
    }

    func store(_ data: Data, forKey key: String) {
        let url = fileURL(for: key)
        lock.withLock {
            try? data.write(to: url, options: .atomic)
        }
        evictIfNeeded()
    }

    private func fileURL(for key: String) -> URL {
        let safe = key
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        return directory.appendingPathComponent(safe)
    }

    private func evictIfNeeded() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else { return }

        let totalSize = files.compactMap {
            try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize
        }.reduce(0, +)

        guard totalSize > maxBytes else { return }

        let sorted = files.sorted {
            let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return d1 < d2
        }

        var remaining = totalSize
        for file in sorted {
            guard remaining > maxBytes else { break }
            if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                try? FileManager.default.removeItem(at: file)
                remaining -= size
            }
        }
    }
}
