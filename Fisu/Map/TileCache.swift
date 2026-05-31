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
        // Lock only guards the mtime touch (LRU tracking). The subsequent read is
        // safe without the lock: atomic writes (via .atomic) use rename(2), so readers
        // always see either the old complete file or the new complete file — never a
        // partial write.
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
        // Locked so two concurrent stores don't both evict based on stale state.
        lock.withLock {
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
            ) else { return }

            // Single pass: collect (url, size, date) to avoid double metadata reads.
            let entries: [(url: URL, size: Int, date: Date)] = files.compactMap { url in
                guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                      let size = values.fileSize,
                      let date = values.contentModificationDate
                else { return nil }
                return (url, size, date)
            }

            let totalSize = entries.reduce(0) { $0 + $1.size }
            guard totalSize > maxBytes else { return }

            let sorted = entries.sorted { $0.date < $1.date }  // oldest first
            var remaining = totalSize
            for entry in sorted {
                guard remaining > maxBytes else { break }
                try? FileManager.default.removeItem(at: entry.url)
                remaining -= entry.size
            }
        }
    }
}
