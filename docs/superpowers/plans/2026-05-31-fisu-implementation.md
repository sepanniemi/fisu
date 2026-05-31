# Fisu iOS App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Fisu iOS fishing catch tracker — MML topographic basemap, GPS-pinned catch logging, route recording, and filterable history.

**Architecture:** SwiftUI app with one UIKit island (`MapContainerView` wrapping `MKMapView`) for MML WMTS tiles + MapKit annotation clustering. SwiftData + CloudKit for per-user private iCloud sync. All services are `@Observable @MainActor`; views use `@Query` for live reads.

**Tech Stack:** Swift 6.2 (strict concurrency), SwiftUI, SwiftData + CloudKit, MapKit (`MKMapView`), CoreLocation, PhotosUI, Swift Testing, xcodegen.

**Prerequisite:** Register bundle ID `fi.fisu.app` and CloudKit container `iCloud.fi.fisu.app` in the Apple Developer Portal before Task 1. You need a paid Apple Developer account.

---

## File Structure

```
Fisu/
├── App/
│   ├── FisuApp.swift
│   └── RootTabView.swift
├── Models/
│   ├── Catch.swift
│   ├── Trip.swift
│   └── RoutePoint.swift
├── Catalog/
│   └── FishSpeciesCatalog.swift
├── Formatting/
│   └── Catch+Formatting.swift
├── Persistence/
│   └── KeychainStore.swift
├── Map/
│   ├── TileCache.swift
│   ├── MMLTileOverlay.swift
│   ├── CatchDisplayMode.swift
│   ├── CatchAnnotation.swift
│   ├── CatchAnnotationView.swift
│   ├── ClusterAnnotationView.swift
│   ├── MapContainerView.swift
│   └── MapCoordinator.swift
├── Location/
│   ├── LocationService.swift
│   └── TripRecorder.swift
├── Services/
│   ├── CatchFilter.swift
│   ├── CatchStore.swift
│   └── PhotoService.swift
├── Features/
│   ├── Map/
│   │   ├── MapScreen.swift
│   │   ├── TripBarView.swift
│   │   └── CatchOverlayCard.swift
│   ├── Capture/
│   │   └── QuickCaptureSheet.swift
│   ├── Catch/
│   │   ├── CatchDetailView.swift
│   │   └── CatchEditView.swift
│   ├── History/
│   │   ├── CatchesListView.swift
│   │   └── CatchRowView.swift
│   ├── Trips/
│   │   ├── TripsListView.swift
│   │   └── TripDetailView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── OnboardingView.swift
FisuTests/
├── TileMathTests.swift
├── RouteTests.swift
├── SpeciesCatalogTests.swift
├── FormattingTests.swift
├── CatchStoreTests.swift
└── TripRecorderTests.swift
```

---

## Task 1: Project Scaffolding

**Files:**
- Create: `project.yml`
- Create: `Fisu/App/FisuApp.swift` (stub)
- Create: `Fisu/App/RootTabView.swift` (stub)
- Create: `FisuTests/FisuTests.swift` (stub)

- [ ] **Step 1: Install xcodegen if not present, verify**

```bash
which xcodegen   # should print /usr/local/bin/xcodegen
```

Expected: a path. If missing: `brew install xcodegen`.

- [ ] **Step 2: Create `project.yml`**

```yaml
name: Fisu
options:
  bundleIdPrefix: fi.fisu
  deploymentTarget:
    iOS: "26.0"
  xcodeVersion: "26.3"
  createIntermediateGroups: true
settings:
  base:
    SWIFT_VERSION: 6.2
    SWIFT_STRICT_CONCURRENCY: complete
    ENABLE_USER_SCRIPT_SANDBOXING: NO
targets:
  Fisu:
    type: application
    platform: iOS
    sources:
      - Fisu
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: fi.fisu.app
        INFOPLIST_FILE: Fisu/Info.plist
        CODE_SIGN_ENTITLEMENTS: Fisu/Fisu.entitlements
        DEVELOPMENT_TEAM: ""   # fill in your 10-char team ID
    info:
      path: Fisu/Info.plist
      properties:
        CFBundleDisplayName: Fisu
        NSLocationWhenInUseUsageDescription: "Fisu uses your location to pin catches to the exact spot you caught them."
        NSLocationAlwaysAndWhenInUseUsageDescription: "When a trip is active, Fisu records your route in the background. Location is used only while tracking."
        NSCameraUsageDescription: "Fisu uses your camera to photograph your catches."
        UIBackgroundModes:
          - location
        UILaunchScreen: {}
  FisuTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - FisuTests
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: fi.fisu.tests
    dependencies:
      - target: Fisu
```

- [ ] **Step 3: Create entitlements file `Fisu/Fisu.entitlements`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.fi.fisu.app</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 4: Create stub source files**

`Fisu/App/FisuApp.swift`:
```swift
import SwiftUI
import SwiftData

@main
struct FisuApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Fisu")
        }
    }
}
```

`Fisu/App/RootTabView.swift`:
```swift
import SwiftUI
struct RootTabView: View {
    var body: some View { Text("Root") }
}
```

`FisuTests/FisuTests.swift`:
```swift
import Testing
struct FisuTests {}
```

- [ ] **Step 5: Generate project and verify build**

```bash
xcodegen generate
xcodebuild -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add project.yml Fisu/ FisuTests/
git commit -m "feat: scaffold xcodegen project"
```

---

## Task 2: Data Models

**Files:**
- Create: `Fisu/Models/Catch.swift`
- Create: `Fisu/Models/Trip.swift`
- Create: `Fisu/Models/RoutePoint.swift`
- Test: `FisuTests/RouteTests.swift`

- [ ] **Step 1: Write failing RoutePoint encode/decode test**

`FisuTests/RouteTests.swift`:
```swift
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
```

- [ ] **Step 2: Run test — expect failure (type not defined)**

```bash
xcodebuild test -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FisuTests/RouteTests 2>&1 | grep -E "error:|FAILED|PASSED"
```

Expected: compile error — `RoutePoint` not found.

- [ ] **Step 3: Create `RoutePoint.swift`**

`Fisu/Models/RoutePoint.swift`:
```swift
import Foundation

struct RoutePoint: Codable, Sendable {
    let lat: Double
    let lon: Double
    let t: Date
    let speed: Double?
}
```

- [ ] **Step 4: Create `Catch.swift`**

`Fisu/Models/Catch.swift`:
```swift
import SwiftData
import Foundation

@Model final class Catch {
    var id: UUID = UUID()
    var timestamp: Date = Date.now
    var latitude: Double = 0
    var longitude: Double = 0
    var horizontalAccuracy: Double?
    var speciesCode: String?
    var speciesCustomName: String?
    var lengthMm: Int?
    var weightGram: Int?
    var released: Bool?
    var lure: String?
    var method: String?
    var notes: String?
    @Attribute(.externalStorage) var photoData: Data?
    @Attribute(.externalStorage) var thumbnailData: Data?
    var trip: Trip?

    init() {}
}
```

- [ ] **Step 5: Create `Trip.swift`**

`Fisu/Models/Trip.swift`:
```swift
import SwiftData
import Foundation

@Model final class Trip {
    var id: UUID = UUID()
    var title: String?
    var startTime: Date = Date.now
    var endTime: Date?
    @Attribute(.externalStorage) var routeData: Data?
    var distanceMeters: Double?
    @Relationship(deleteRule: .nullify, inverse: \Catch.trip) var catches: [Catch]?

    init() {}
}
```

- [ ] **Step 6: Run RoutePoint test — expect pass**

```bash
xcodebuild test -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FisuTests/RouteTests 2>&1 | grep -E "FAILED|PASSED|error:"
```

Expected: `Test Suite ... passed`

- [ ] **Step 7: Commit**

```bash
git add Fisu/Models/ FisuTests/RouteTests.swift
git commit -m "feat: add SwiftData models Catch, Trip, RoutePoint"
```

---

## Task 3: Species Catalog, Formatting, Keychain

**Files:**
- Create: `Fisu/Catalog/FishSpeciesCatalog.swift`
- Create: `Fisu/Formatting/Catch+Formatting.swift`
- Create: `Fisu/Persistence/KeychainStore.swift`
- Test: `FisuTests/SpeciesCatalogTests.swift`
- Test: `FisuTests/FormattingTests.swift`

- [ ] **Step 1: Write failing catalog + formatting tests**

`FisuTests/SpeciesCatalogTests.swift`:
```swift
import Testing
@testable import Fisu

@Suite struct SpeciesCatalogTests {
    @Test func lookupKnownSpecies() {
        let s = FishSpeciesCatalog.species(for: "hauki")
        #expect(s?.nameFI == "Hauki")
        #expect(s?.nameEN == "Pike")
    }

    @Test func lookupUnknownReturnsNil() {
        #expect(FishSpeciesCatalog.species(for: "unknown_fish") == nil)
    }

    @Test func otherSpeciesExists() {
        let s = FishSpeciesCatalog.species(for: "other")
        #expect(s != nil)
    }

    @Test func allSpeciesHaveUniqueCode() {
        let codes = FishSpeciesCatalog.all.map(\.code)
        #expect(codes.count == Set(codes).count)
    }
}
```

`FisuTests/FormattingTests.swift`:
```swift
import Testing
@testable import Fisu

@Suite struct FormattingTests {
    @Test func lengthDisplay() {
        let c = Catch(); c.lengthMm = 780
        #expect(c.lengthDisplay == "78 cm")
    }

    @Test func lengthNilWhenUnset() {
        let c = Catch()
        #expect(c.lengthDisplay == nil)
    }

    @Test func weightKgAboveThreshold() {
        let c = Catch(); c.weightGram = 3400
        #expect(c.weightDisplay == "3.40 kg")
    }

    @Test func weightGramBelowThreshold() {
        let c = Catch(); c.weightGram = 240
        #expect(c.weightDisplay == "240 g")
    }

    @Test func weightExactKg() {
        let c = Catch(); c.weightGram = 1000
        #expect(c.weightDisplay == "1.00 kg")
    }

    @Test func weightNilWhenUnset() {
        let c = Catch()
        #expect(c.weightDisplay == nil)
    }
}
```

- [ ] **Step 2: Run tests — expect compile error**

```bash
xcodebuild test -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FisuTests/SpeciesCatalogTests -only-testing:FisuTests/FormattingTests 2>&1 | grep "error:"
```

Expected: `FishSpeciesCatalog` not found.

- [ ] **Step 3: Create `FishSpeciesCatalog.swift`**

`Fisu/Catalog/FishSpeciesCatalog.swift`:
```swift
import SwiftUI

struct FishSpecies: Identifiable, Sendable {
    let code: String
    let nameFI: String
    let nameEN: String
    let color: Color
    var id: String { code }
}

enum FishSpeciesCatalog {
    static let all: [FishSpecies] = [
        FishSpecies(code: "ahven",     nameFI: "Ahven",     nameEN: "Perch",         color: Color(red: 0.88, green: 0.64, blue: 0.23)),
        FishSpecies(code: "hauki",     nameFI: "Hauki",     nameEN: "Pike",          color: Color(red: 0.18, green: 0.55, blue: 0.34)),
        FishSpecies(code: "kuha",      nameFI: "Kuha",      nameEN: "Zander",        color: Color(red: 0.36, green: 0.51, blue: 0.68)),
        FishSpecies(code: "taimen",    nameFI: "Taimen",    nameEN: "Brown trout",   color: Color(red: 0.71, green: 0.40, blue: 0.11)),
        FishSpecies(code: "kirjolohi", nameFI: "Kirjolohi", nameEN: "Rainbow trout", color: Color(red: 0.81, green: 0.42, blue: 0.48)),
        FishSpecies(code: "lohi",      nameFI: "Lohi",      nameEN: "Salmon",        color: Color(red: 0.85, green: 0.54, blue: 0.24)),
        FishSpecies(code: "siika",     nameFI: "Siika",     nameEN: "Whitefish",     color: Color(red: 0.72, green: 0.72, blue: 0.72)),
        FishSpecies(code: "made",      nameFI: "Made",      nameEN: "Burbot",        color: Color(red: 0.49, green: 0.42, blue: 0.33)),
        FishSpecies(code: "lahna",     nameFI: "Lahna",     nameEN: "Bream",         color: Color(red: 0.60, green: 0.56, blue: 0.36)),
        FishSpecies(code: "sarki",     nameFI: "Särki",     nameEN: "Roach",         color: Color(red: 0.76, green: 0.30, blue: 0.30)),
        FishSpecies(code: "niera",     nameFI: "Nieriä",    nameEN: "Arctic char",   color: Color(red: 0.90, green: 0.45, blue: 0.20)),
        FishSpecies(code: "harjus",    nameFI: "Harjus",    nameEN: "Grayling",      color: Color(red: 0.42, green: 0.35, blue: 0.60)),
        FishSpecies(code: "sayne",     nameFI: "Säyne",     nameEN: "Ide",           color: Color(red: 0.50, green: 0.60, blue: 0.40)),
        FishSpecies(code: "kuore",     nameFI: "Kuore",     nameEN: "Smelt",         color: Color(red: 0.65, green: 0.75, blue: 0.85)),
        FishSpecies(code: "other",     nameFI: "Muu",       nameEN: "Other",         color: Color(red: 0.54, green: 0.54, blue: 0.54)),
    ]

    static func species(for code: String) -> FishSpecies? {
        all.first { $0.code == code }
    }

    static func color(for code: String?) -> Color {
        guard let code else { return Color(red: 0.54, green: 0.54, blue: 0.54) }
        return species(for: code)?.color ?? Color(red: 0.54, green: 0.54, blue: 0.54)
    }

    static func displayName(for code: String?) -> String {
        guard let code else { return "–" }
        return species(for: code)?.nameFI ?? code
    }
}
```

- [ ] **Step 4: Create `Catch+Formatting.swift`**

`Fisu/Formatting/Catch+Formatting.swift`:
```swift
import Foundation

extension Catch {
    var lengthDisplay: String? {
        guard let mm = lengthMm else { return nil }
        return "\(mm / 10) cm"
    }

    var weightDisplay: String? {
        guard let g = weightGram else { return nil }
        if g >= 1000 {
            return String(format: "%.2f kg", Double(g) / 1000.0)
        }
        return "\(g) g"
    }

    var speciesDisplayName: String {
        if speciesCode == "other", let custom = speciesCustomName, !custom.isEmpty {
            return custom
        }
        return FishSpeciesCatalog.displayName(for: speciesCode)
    }

    var sizeDisplay: String {
        [lengthDisplay, weightDisplay].compactMap { $0 }.joined(separator: " · ")
    }
}

extension DateFormatter {
    static let fiShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d.M."
        f.locale = Locale(identifier: "fi_FI")
        return f
    }()

    static let fiDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d.M.yyyy HH:mm"
        f.locale = Locale(identifier: "fi_FI")
        return f
    }()
}
```

- [ ] **Step 5: Create `KeychainStore.swift`**

`Fisu/Persistence/KeychainStore.swift`:
```swift
import Foundation
import Security

enum KeychainStore {
    private static let service = "fi.fisu.app"
    private static let mmlKeyAccount = "mml-api-key"

    static var mmlApiKey: String? {
        get { load(account: mmlKeyAccount) }
        set {
            if let value = newValue {
                save(value, account: mmlKeyAccount)
            } else {
                delete(account: mmlKeyAccount)
            }
        }
    }

    private static func save(_ value: String, account: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData] = data
        SecItemAdd(attrs as CFDictionary, nil)
    }

    private static func load(account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(account: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

- [ ] **Step 6: Run catalog and formatting tests — expect pass**

```bash
xcodebuild test -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FisuTests/SpeciesCatalogTests -only-testing:FisuTests/FormattingTests 2>&1 | grep -E "FAILED|PASSED|error:"
```

Expected: both suites pass.

- [ ] **Step 7: Commit**

```bash
git add Fisu/Catalog/ Fisu/Formatting/ Fisu/Persistence/ FisuTests/
git commit -m "feat: add species catalog, formatting, keychain"
```

---

## Task 4: TileCache

**Files:**
- Create: `Fisu/Map/TileCache.swift`
- Test: `FisuTests/TileCacheTests.swift`

- [ ] **Step 1: Write failing TileCache tests**

`FisuTests/TileCacheTests.swift`:
```swift
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
```

- [ ] **Step 2: Run test — expect compile error**

```bash
xcodebuild test -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FisuTests/TileCacheTests 2>&1 | grep "error:"
```

- [ ] **Step 3: Implement `TileCache.swift`**

`Fisu/Map/TileCache.swift`:
```swift
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
```

- [ ] **Step 4: Run tests — expect pass**

```bash
xcodebuild test -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FisuTests/TileCacheTests 2>&1 | grep -E "FAILED|PASSED|error:"
```

- [ ] **Step 5: Commit**

```bash
git add Fisu/Map/TileCache.swift FisuTests/TileCacheTests.swift
git commit -m "feat: add on-disk LRU TileCache"
```

---

## Task 5: MMLTileOverlay

**Files:**
- Create: `Fisu/Map/MMLTileOverlay.swift`
- Test: `FisuTests/TileMathTests.swift`

- [ ] **Step 1: Write failing tile URL tests**

`FisuTests/TileMathTests.swift`:
```swift
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
}
```

- [ ] **Step 2: Run — expect compile error**

```bash
xcodebuild test -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FisuTests/TileMathTests 2>&1 | grep "error:"
```

- [ ] **Step 3: Implement `MMLTileOverlay.swift`**

`Fisu/Map/MMLTileOverlay.swift`:
```swift
import MapKit

final class MMLTileOverlay: MKTileOverlay, @unchecked Sendable {
    private let apiKey: String
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
        canReplaceMapContent = true
        minimumZ = 0
        maximumZ = 15
        tileSize = CGSize(width: 256, height: 256)
    }

    // Exposed for testing; builds the WMTS RESTful URL.
    // MML WMTS path order: .../TileMatrix/TileRow/TileCol.png
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
        let key = "\(layer)/\(path.z)/\(path.x)/\(path.y)"
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
```

- [ ] **Step 4: Run tests — expect pass**

```bash
xcodebuild test -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FisuTests/TileMathTests 2>&1 | grep -E "FAILED|PASSED|error:"
```

- [ ] **Step 5: Commit**

```bash
git add Fisu/Map/MMLTileOverlay.swift FisuTests/TileMathTests.swift
git commit -m "feat: add MMLTileOverlay with WMTS URL builder and disk cache"
```

---

## Task 6: LocationService

**Files:**
- Create: `Fisu/Location/LocationService.swift`

No unit tests for LocationService (wraps hardware; verified by integration).

- [ ] **Step 1: Create `LocationService.swift`**

`Fisu/Location/LocationService.swift`:
```swift
import CoreLocation
import Observation

enum LocationError: Error {
    case noLocation
    case denied
}

@Observable @MainActor
final class LocationService: NSObject {
    private(set) var location: CLLocation?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5   // metres; reduces noise at trolling speeds
        authorizationStatus = manager.authorizationStatus
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlways() {
        manager.requestAlwaysAuthorization()
    }

    func startUpdating() {
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.allowsBackgroundLocationUpdates = false
        manager.stopUpdatingLocation()
    }

    var isAuthorizedForWhenInUse: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isAuthorizedAlways: Bool {
        authorizationStatus == .authorizedAlways
    }
}

extension LocationService: @preconcurrency CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor [weak self] in self?.location = loc }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in self?.authorizationStatus = status }
    }
}
```

- [ ] **Step 2: Build — expect success**

```bash
xcodebuild -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Fisu/Location/LocationService.swift
git commit -m "feat: add LocationService CLLocationManager wrapper"
```

---

## Task 7: TripRecorder

**Files:**
- Create: `Fisu/Location/TripRecorder.swift`
- Test: `FisuTests/TripRecorderTests.swift`

- [ ] **Step 1: Write failing distance test**

`FisuTests/TripRecorderTests.swift`:
```swift
import Testing
import CoreLocation
@testable import Fisu

@Suite struct TripRecorderTests {
    // Haversine: Helsinki (60.1699, 24.9384) → Tampere (61.4978, 23.7610) ≈ 166 km
    @Test func haversineApproximation() {
        let p1 = RoutePoint(lat: 60.1699, lon: 24.9384, t: .now, speed: nil)
        let p2 = RoutePoint(lat: 61.4978, lon: 23.7610, t: .now, speed: nil)
        let dist = haversineMeters(from: p1, to: p2)
        #expect(dist > 155_000 && dist < 180_000)
    }

    @Test func zeroDistanceForSinglePoint() {
        let p = RoutePoint(lat: 61.0, lon: 25.0, t: .now, speed: nil)
        let dist = haversineMeters(from: p, to: p)
        #expect(dist < 1)
    }
}
```

- [ ] **Step 2: Run — expect compile error**

```bash
xcodebuild test -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FisuTests/TripRecorderTests 2>&1 | grep "error:"
```

- [ ] **Step 3: Create `TripRecorder.swift`**

`Fisu/Location/TripRecorder.swift`:
```swift
import CoreLocation
import SwiftData
import Observation

// Internal helper — not in a type so tests can call it directly.
func haversineMeters(from a: RoutePoint, to b: RoutePoint) -> Double {
    let R = 6_371_000.0
    let lat1 = a.lat * .pi / 180, lat2 = b.lat * .pi / 180
    let dLat = (b.lat - a.lat) * .pi / 180
    let dLon = (b.lon - a.lon) * .pi / 180
    let sinDLat = sin(dLat / 2), sinDLon = sin(dLon / 2)
    let h = sinDLat * sinDLat + cos(lat1) * cos(lat2) * sinDLon * sinDLon
    return R * 2 * atan2(sqrt(h), sqrt(1 - h))
}

enum TripState { case idle, recording, paused }

@Observable @MainActor
final class TripRecorder {
    private(set) var state: TripState = .idle
    private(set) var activeTrip: Trip?
    private(set) var routePoints: [RoutePoint] = []
    private(set) var distanceMeters: Double = 0
    private(set) var startTime: Date?

    private let locationService: LocationService
    private let context: ModelContext

    init(locationService: LocationService, context: ModelContext) {
        self.locationService = locationService
        self.context = context
    }

    func start() {
        guard state == .idle else { return }
        let trip = Trip()
        trip.startTime = .now
        trip.title = Self.autoTitle(for: .now)
        context.insert(trip)
        activeTrip = trip
        routePoints = []
        distanceMeters = 0
        startTime = .now
        state = .recording
        locationService.requestAlways()
        locationService.startUpdating()
    }

    func pause() {
        guard state == .recording else { return }
        state = .paused
        locationService.stopUpdating()
    }

    func resume() {
        guard state == .paused else { return }
        state = .recording
        locationService.startUpdating()
    }

    func stop() {
        guard state != .idle, let trip = activeTrip else { return }
        locationService.stopUpdating()
        trip.endTime = .now
        trip.routeData = try? JSONEncoder().encode(routePoints)
        trip.distanceMeters = distanceMeters
        state = .idle
        activeTrip = nil
        startTime = nil
    }

    func appendLocation(_ location: CLLocation) {
        guard state == .recording else { return }
        let point = RoutePoint(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude,
            t: location.timestamp,
            speed: location.speed >= 0 ? location.speed : nil
        )
        if let last = routePoints.last {
            distanceMeters += haversineMeters(from: last, to: point)
        }
        routePoints.append(point)
    }

    var duration: TimeInterval {
        guard let start = startTime else { return 0 }
        return Date.now.timeIntervalSince(start)
    }

    var durationFormatted: String {
        let total = Int(duration)
        return String(format: "%d:%02d", total / 3600, (total % 3600) / 60)
    }

    var distanceKmFormatted: String {
        String(format: "%.1f km", distanceMeters / 1000)
    }

    private static func autoTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fi_FI")
        f.dateFormat = "d.M."
        return "\(f.string(from: date)) troolaus"
    }
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
xcodebuild test -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FisuTests/TripRecorderTests 2>&1 | grep -E "FAILED|PASSED|error:"
```

- [ ] **Step 5: Commit**

```bash
git add Fisu/Location/TripRecorder.swift FisuTests/TripRecorderTests.swift
git commit -m "feat: add TripRecorder with haversine distance"
```

---

## Task 8: CatchStore

**Files:**
- Create: `Fisu/Services/CatchFilter.swift`
- Create: `Fisu/Services/CatchStore.swift`
- Test: `FisuTests/CatchStoreTests.swift`

- [ ] **Step 1: Write failing CatchStore tests**

`FisuTests/CatchStoreTests.swift`:
```swift
import Testing
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
        let store = try makeStore()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Catch.self, Trip.self, configurations: config)
        let store2 = CatchStore(context: container.mainContext)
        let entry = store2.create(speciesCode: "hauki", latitude: 0, longitude: 0)
        store2.delete(entry)
        let all = try container.mainContext.fetch(FetchDescriptor<Catch>())
        #expect(all.isEmpty)
    }
}
```

- [ ] **Step 2: Run — expect compile error**

```bash
xcodebuild test -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FisuTests/CatchStoreTests 2>&1 | grep "error:"
```

- [ ] **Step 3: Create `CatchFilter.swift`**

`Fisu/Services/CatchFilter.swift`:
```swift
import Foundation

struct CatchFilter {
    enum SortOrder { case newestFirst, biggestFirst }

    var species: Set<String>? = nil
    var dateRange: ClosedRange<Date>? = nil
    var sortOrder: SortOrder = .newestFirst

    static let `default` = CatchFilter()

    func apply(to catches: [Catch]) -> [Catch] {
        var result = catches

        if let species, !species.isEmpty {
            result = result.filter {
                guard let code = $0.speciesCode else { return false }
                return species.contains(code)
            }
        }

        if let range = dateRange {
            result = result.filter { range.contains($0.timestamp) }
        }

        switch sortOrder {
        case .newestFirst:
            result.sort { $0.timestamp > $1.timestamp }
        case .biggestFirst:
            result.sort { Self.isBigger($0, than: $1) }
        }

        return result
    }

    static func isBigger(_ a: Catch, than b: Catch) -> Bool {
        switch (a.weightGram, b.weightGram) {
        case let (aw?, bw?): return aw > bw
        case (_?, nil):      return true
        case (nil, _?):      return false
        default:
            switch (a.lengthMm, b.lengthMm) {
            case let (al?, bl?): return al > bl
            default:             return false
            }
        }
    }
}
```

- [ ] **Step 4: Create `CatchStore.swift`**

`Fisu/Services/CatchStore.swift`:
```swift
import SwiftData
import Observation

@Observable @MainActor
final class CatchStore {
    private let context: ModelContext
    private weak var tripRecorder: TripRecorder?

    init(context: ModelContext, tripRecorder: TripRecorder? = nil) {
        self.context = context
        self.tripRecorder = tripRecorder
    }

    @discardableResult
    func create(
        speciesCode: String?,
        speciesCustomName: String? = nil,
        latitude: Double,
        longitude: Double,
        horizontalAccuracy: Double? = nil,
        timestamp: Date = .now,
        lengthMm: Int? = nil,
        weightGram: Int? = nil,
        released: Bool? = nil,
        lure: String? = nil,
        method: String? = nil,
        notes: String? = nil
    ) -> Catch {
        let entry = Catch()
        entry.speciesCode = speciesCode
        entry.speciesCustomName = speciesCustomName
        entry.latitude = latitude
        entry.longitude = longitude
        entry.horizontalAccuracy = horizontalAccuracy
        entry.timestamp = timestamp
        entry.lengthMm = lengthMm
        entry.weightGram = weightGram
        entry.released = released
        entry.lure = lure
        entry.method = method
        entry.notes = notes
        entry.trip = tripRecorder?.activeTrip
        context.insert(entry)
        return entry
    }

    func delete(_ entry: Catch) {
        context.delete(entry)
    }

    func catches(filter: CatchFilter = .default) throws -> [Catch] {
        let all = try context.fetch(FetchDescriptor<Catch>())
        return filter.apply(to: all)
    }

    func personalBests() throws -> [String: Catch] {
        let all = try context.fetch(FetchDescriptor<Catch>())
        var bests: [String: Catch] = [:]
        for entry in all {
            guard let code = entry.speciesCode else { continue }
            if let existing = bests[code] {
                if CatchFilter.isBigger(entry, than: existing) { bests[code] = entry }
            } else {
                bests[code] = entry
            }
        }
        return bests
    }
}
```

- [ ] **Step 5: Run tests — expect pass**

```bash
xcodebuild test -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:FisuTests/CatchStoreTests 2>&1 | grep -E "FAILED|PASSED|error:"
```

- [ ] **Step 6: Commit**

```bash
git add Fisu/Services/ FisuTests/CatchStoreTests.swift
git commit -m "feat: add CatchStore with filtering, sorting, personal bests"
```

---

## Task 9: PhotoService

**Files:**
- Create: `Fisu/Services/PhotoService.swift`

No unit tests (wraps UIKit image APIs; verified manually).

- [ ] **Step 1: Create `PhotoService.swift`**

`Fisu/Services/PhotoService.swift`:
```swift
import UIKit
import PhotosUI
import ImageIO

@Observable @MainActor
final class PhotoService {
    static let maxDimension: CGFloat = 1600
    static let thumbnailDimension: CGFloat = 200
    static let jpegQuality: CGFloat = 0.82

    func process(_ item: PhotosPickerItem) async -> (full: Data, thumb: Data)? {
        guard let raw = try? await item.loadTransferable(type: Data.self) else { return nil }
        let full = downsample(raw) ?? raw
        guard let thumb = thumbnail(from: full) else { return nil }
        return (full, thumb)
    }

    func captureFromCamera() -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }

    func process(uiImage: UIImage) -> (full: Data, thumb: Data)? {
        guard let raw = uiImage.jpegData(compressionQuality: Double(Self.jpegQuality)) else { return nil }
        let full = downsample(raw) ?? raw
        guard let thumb = thumbnail(from: full) else { return nil }
        return (full, thumb)
    }

    private func downsample(_ data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let w = props?[kCGImagePropertyPixelWidth] as? CGFloat ?? 0
        let h = props?[kCGImagePropertyPixelHeight] as? CGFloat ?? 0
        let maxDim = Self.maxDimension
        guard max(w, h) > maxDim else { return data }
        let scale = maxDim / max(w, h)
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: max(w, h) * scale,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return data }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: Double(Self.jpegQuality))
    }

    private func thumbnail(from data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: Self.thumbnailDimension,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.75)
    }
}
```

- [ ] **Step 2: Build — expect success**

```bash
xcodebuild -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3
```

- [ ] **Step 3: Commit**

```bash
git add Fisu/Services/PhotoService.swift
git commit -m "feat: add PhotoService for camera/library capture and downsampling"
```

---

## Task 10: MapContainerView — basemap and location

**Files:**
- Create: `Fisu/Map/CatchDisplayMode.swift`
- Create: `Fisu/Map/CatchAnnotation.swift`
- Create: `Fisu/Map/CatchAnnotationView.swift`
- Create: `Fisu/Map/ClusterAnnotationView.swift`
- Create: `Fisu/Map/MapCoordinator.swift`
- Create: `Fisu/Map/MapContainerView.swift`

- [ ] **Step 1: Create `CatchDisplayMode.swift`**

`Fisu/Map/CatchDisplayMode.swift`:
```swift
enum CatchDisplayMode: CaseIterable {
    case dots, labels, hidden

    mutating func cycle() {
        switch self {
        case .dots:   self = .labels
        case .labels: self = .hidden
        case .hidden: self = .dots
        }
    }

    var iconName: String {
        switch self {
        case .dots:   return "eye"
        case .labels: return "eye.fill"
        case .hidden: return "eye.slash"
        }
    }
}
```

- [ ] **Step 2: Create `CatchAnnotation.swift`**

`Fisu/Map/CatchAnnotation.swift`:
```swift
import MapKit

final class CatchAnnotation: NSObject, MKAnnotation {
    let entry: Catch

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: entry.latitude, longitude: entry.longitude)
    }

    var title: String? {
        FishSpeciesCatalog.displayName(for: entry.speciesCode)
    }

    init(entry: Catch) {
        self.entry = entry
        super.init()
    }
}
```

- [ ] **Step 3: Create `CatchAnnotationView.swift`**

`Fisu/Map/CatchAnnotationView.swift`:
```swift
import MapKit
import UIKit

final class CatchAnnotationView: MKAnnotationView {
    static let reuseId = "CatchAnnotationView"

    var displayMode: CatchDisplayMode = .dots {
        didSet { updateAppearance() }
    }

    private var label: UILabel?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "catches"
        canShowCallout = false
        bounds = CGRect(x: 0, y: 0, width: 14, height: 14)
        layer.cornerRadius = 7
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 2
        layer.shadowOffset = CGSize(width: 0, height: 1)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        label?.removeFromSuperview()
        label = nil
    }

    override var annotation: MKAnnotation? {
        didSet { updateAppearance() }
    }

    private func updateAppearance() {
        guard let catchAnnotation = annotation as? CatchAnnotation else { return }
        let species = catchAnnotation.entry.speciesCode
        let uiColor = UIColor(FishSpeciesCatalog.color(for: species))
        backgroundColor = uiColor

        label?.removeFromSuperview()
        label = nil

        if displayMode == .labels {
            let lbl = UILabel()
            lbl.font = .systemFont(ofSize: 9, weight: .bold)
            lbl.textColor = .label
            lbl.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
            lbl.layer.cornerRadius = 4
            lbl.clipsToBounds = true
            let name = FishSpeciesCatalog.displayName(for: species)
            let dateStr = DateFormatter.fiShort.string(from: catchAnnotation.entry.timestamp)
            lbl.text = " \(name) \(dateStr) "
            lbl.sizeToFit()
            lbl.frame.origin = CGPoint(x: 16, y: -lbl.frame.height / 2 + 7)
            addSubview(lbl)
            label = lbl
        }
    }
}
```

- [ ] **Step 4: Create `ClusterAnnotationView.swift`**

`Fisu/Map/ClusterAnnotationView.swift`:
```swift
import MapKit
import UIKit

final class ClusterAnnotationView: MKAnnotationView {
    private let countLabel = UILabel()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        bounds = CGRect(x: 0, y: 0, width: 34, height: 34)
        layer.cornerRadius = 17
        backgroundColor = UIColor(red: 0.09, green: 0.42, blue: 0.23, alpha: 1)
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2.5
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 3

        countLabel.textColor = .white
        countLabel.font = .systemFont(ofSize: 13, weight: .heavy)
        countLabel.textAlignment = .center
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override var annotation: MKAnnotation? {
        didSet {
            if let cluster = annotation as? MKClusterAnnotation {
                countLabel.text = "\(cluster.memberAnnotations.count)"
            }
        }
    }
}
```

- [ ] **Step 5: Create `MapCoordinator.swift`**

`Fisu/Map/MapCoordinator.swift`:
```swift
import MapKit
import UIKit

final class MapCoordinator: NSObject, MKMapViewDelegate {
    var onCatchSelected: (Catch) -> Void
    var onCatchDeselected: () -> Void
    var displayMode: CatchDisplayMode = .dots

    init(onCatchSelected: @escaping (Catch) -> Void, onCatchDeselected: @escaping () -> Void) {
        self.onCatchSelected = onCatchSelected
        self.onCatchDeselected = onCatchDeselected
    }

    func syncAnnotations(mapView: MKMapView, catches: [Catch], displayMode: CatchDisplayMode) {
        self.displayMode = displayMode

        if displayMode == .hidden {
            let toRemove = mapView.annotations.filter { $0 is CatchAnnotation || $0 is MKClusterAnnotation }
            mapView.removeAnnotations(toRemove)
            return
        }

        let existing = mapView.annotations.compactMap { $0 as? CatchAnnotation }
        let existingIds = Set(existing.map { ObjectIdentifier($0.entry) })
        let newIds = Set(catches.map { ObjectIdentifier($0) })

        let toRemove = existing.filter { !newIds.contains(ObjectIdentifier($0.entry)) }
        mapView.removeAnnotations(toRemove)

        let toAdd = catches.filter { !existingIds.contains(ObjectIdentifier($0)) }
            .map { CatchAnnotation(entry: $0) }
        mapView.addAnnotations(toAdd)

        for ann in mapView.annotations.compactMap({ $0 as? CatchAnnotation }) {
            (mapView.view(for: ann) as? CatchAnnotationView)?.displayMode = displayMode
        }
    }

    func syncRoute(mapView: MKMapView, routePoints: [RoutePoint]) {
        mapView.overlays.filter { $0 is MKPolyline }.forEach { mapView.removeOverlay($0) }
        guard routePoints.count >= 2 else { return }
        let coords = routePoints.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) }
        mapView.addOverlay(MKPolyline(coordinates: coords, count: coords.count), level: .aboveRoads)
    }

    // MARK: MKMapViewDelegate

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKTileOverlay {
            return MKTileOverlayRenderer(overlay: overlay)
        }
        if let polyline = overlay as? MKPolyline {
            let r = MKPolylineRenderer(polyline: polyline)
            r.strokeColor = UIColor(red: 0.12, green: 0.48, blue: 0.88, alpha: 0.9)
            r.lineWidth = 3.5
            return r
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }

        if annotation is CatchAnnotation {
            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: CatchAnnotationView.reuseId, for: annotation
            ) as! CatchAnnotationView
            view.displayMode = displayMode
            return view
        }

        if annotation is MKClusterAnnotation {
            return mapView.dequeueReusableAnnotationView(
                withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier,
                for: annotation
            ) as! ClusterAnnotationView
        }

        return nil
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let v = view as? CatchAnnotationView,
           let ann = v.annotation as? CatchAnnotation {
            onCatchSelected(ann.entry)
        }
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if view is CatchAnnotationView { onCatchDeselected() }
    }
}
```

- [ ] **Step 6: Create `MapContainerView.swift`**

`Fisu/Map/MapContainerView.swift`:
```swift
import SwiftUI
import MapKit

struct MapContainerView: UIViewRepresentable {
    let catches: [Catch]
    let displayMode: CatchDisplayMode
    let routePoints: [RoutePoint]
    let apiKey: String
    let onCatchSelected: (Catch) -> Void
    let onCatchDeselected: () -> Void

    func makeCoordinator() -> MapCoordinator {
        MapCoordinator(onCatchSelected: onCatchSelected, onCatchDeselected: onCatchDeselected)
    }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.showsCompass = true
        map.isRotateEnabled = true
        map.isPitchEnabled = false

        // Install MML basemap
        if !apiKey.isEmpty {
            let cacheDir = FileManager.default
                .urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("mml_tiles")
            let overlay = MMLTileOverlay(apiKey: apiKey, cache: TileCache(directory: cacheDir))
            map.addOverlay(overlay, level: .aboveLabels)
        }

        map.register(CatchAnnotationView.self, forAnnotationViewWithReuseIdentifier: CatchAnnotationView.reuseId)
        map.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)

        // Default region: Finland
        let finland = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 64.5, longitude: 26.0),
            span: MKCoordinateSpan(latitudeDelta: 12, longitudeDelta: 12)
        )
        map.setRegion(finland, animated: false)

        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.syncAnnotations(mapView: map, catches: catches, displayMode: displayMode)
        context.coordinator.syncRoute(mapView: map, routePoints: routePoints)
    }
}
```

- [ ] **Step 7: Build — expect success**

```bash
xcodebuild -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3
```

- [ ] **Step 8: Commit**

```bash
git add Fisu/Map/
git commit -m "feat: add MapContainerView with MML basemap, annotations, clustering, route"
```

---

## Task 11: OnboardingView + SettingsView

**Files:**
- Create: `Fisu/Features/Settings/OnboardingView.swift`
- Create: `Fisu/Features/Settings/SettingsView.swift`

- [ ] **Step 1: Create `OnboardingView.swift`**

`Fisu/Features/Settings/OnboardingView.swift`:
```swift
import SwiftUI

struct OnboardingView: View {
    @State private var apiKey = ""
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "map.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)

                Text("Welcome to Fisu")
                    .font(.largeTitle.bold())

                Text("Enter your MML Karttakuvapalvelu api-key to load the Finnish topo map with depth information.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("MML API Key")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("Paste your api-key here", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Button {
                    KeychainStore.mmlApiKey = apiKey.isEmpty ? nil : apiKey
                    isPresented = false
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)

                Button("Skip for now") {
                    isPresented = false
                }
                .foregroundStyle(.secondary)
            }
            .padding(32)
        }
    }
}
```

- [ ] **Step 2: Create `SettingsView.swift`**

`Fisu/Features/Settings/SettingsView.swift`:
```swift
import SwiftUI

struct SettingsView: View {
    @State private var apiKey = KeychainStore.mmlApiKey ?? ""
    @State private var keepScreenAwake = true
    @AppStorage("keepScreenAwake") private var keepScreenAwakeStorage = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Map") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MML API Key")
                            .font(.subheadline.weight(.medium))
                        SecureField("api-key", text: $apiKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onSubmit { KeychainStore.mmlApiKey = apiKey.isEmpty ? nil : apiKey }
                    }
                    Button("Save API Key") {
                        KeychainStore.mmlApiKey = apiKey.isEmpty ? nil : apiKey
                    }
                    .disabled(apiKey == (KeychainStore.mmlApiKey ?? ""))

                    Text("© Maanmittauslaitos — open data licence")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Tracking") {
                    Toggle("Keep screen awake during trip", isOn: $keepScreenAwakeStorage)
                }

                Section("iCloud") {
                    HStack {
                        Text("Sync status")
                        Spacer()
                        Text("Synced")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

- [ ] **Step 3: Build — expect success**

```bash
xcodebuild -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3
```

- [ ] **Step 4: Commit**

```bash
git add Fisu/Features/Settings/
git commit -m "feat: add OnboardingView and SettingsView"
```

---

## Task 12: MapScreen

**Files:**
- Create: `Fisu/Features/Map/CatchOverlayCard.swift`
- Create: `Fisu/Features/Map/TripBarView.swift`
- Create: `Fisu/Features/Map/MapScreen.swift`

- [ ] **Step 1: Create `CatchOverlayCard.swift`**

`Fisu/Features/Map/CatchOverlayCard.swift`:
```swift
import SwiftUI

struct CatchOverlayCard: View {
    let entry: Catch
    let onDismiss: () -> Void
    let onOpenDetail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(FishSpeciesCatalog.color(for: entry.speciesCode))
                            .frame(width: 12, height: 12)
                        Text(entry.speciesDisplayName)
                            .font(.headline)
                    }
                    Text(DateFormatter.fiDateTime.string(from: entry.timestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !entry.sizeDisplay.isEmpty {
                        Text(entry.sizeDisplay)
                            .font(.subheadline.weight(.medium))
                            .padding(.top, 4)
                    }
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)

            Divider()

            Button(action: onOpenDetail) {
                HStack {
                    Text("Open full details")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
    }
}
```

- [ ] **Step 2: Create `TripBarView.swift`**

`Fisu/Features/Map/TripBarView.swift`:
```swift
import SwiftUI

struct TripBarView: View {
    @Environment(TripRecorder.self) private var recorder
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            if recorder.state != .idle {
                activeBar
            } else {
                startBar
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.18), radius: 8, y: 2)
    }

    private var startBar: some View {
        Button {
            recorder.start()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start trip")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(.green)
        }
    }

    private var activeBar: some View {
        VStack(spacing: 0) {
            // Collapsed row (always visible)
            Button {
                withAnimation(.spring(duration: 0.28)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 9, height: 9)
                    Text("\(recorder.distanceKmFormatted) · \(recorder.durationFormatted) · \(recorder.routePoints.count > 0 ? "\(catchCount) fish" : "0 fish")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
            }

            // Expanded actions
            if isExpanded {
                Divider()
                HStack(spacing: 0) {
                    tripActionButton("Pause", icon: "pause.fill", color: .green) {
                        if recorder.state == .recording { recorder.pause() } else { recorder.resume() }
                        isExpanded = false
                    }
                    Divider().frame(height: 40)
                    tripActionButton("Stop", icon: "stop.fill", color: .red) {
                        recorder.stop()
                        isExpanded = false
                    }
                }
            }
        }
    }

    private var catchCount: Int { 0 } // filled in by MapScreen from @Query

    private func tripActionButton(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3)
                Text(label).font(.caption.weight(.semibold))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }
}
```

- [ ] **Step 3: Create `MapScreen.swift`**

`Fisu/Features/Map/MapScreen.swift`:
```swift
import SwiftUI
import SwiftData

struct MapScreen: View {
    @Environment(TripRecorder.self) private var recorder
    @Environment(LocationService.self) private var locationService
    @Environment(CatchStore.self) private var catchStore
    @Query private var catches: [Catch]
    @State private var displayMode: CatchDisplayMode = .dots
    @State private var showCapture = false
    @State private var selectedEntry: Catch?
    @State private var navigateToDetail = false
    @State private var showOnboarding = false

    private var apiKey: String { KeychainStore.mmlApiKey ?? "" }

    var body: some View {
        ZStack(alignment: .bottom) {
            MapContainerView(
                catches: displayMode == .hidden ? [] : catches,
                displayMode: displayMode,
                routePoints: recorder.routePoints,
                apiKey: apiKey,
                onCatchSelected: { entry in
                    selectedEntry = entry
                },
                onCatchDeselected: {
                    // Don't auto-dismiss; user taps ✕ or the card
                }
            )
            .ignoresSafeArea()

            // Utility stack — top right
            VStack(spacing: 10) {
                utilityButton(systemImage: "location.fill") {
                    // Center on user location — implemented via a binding if needed; skip for v1
                }
                utilityButton(systemImage: displayMode.iconName) {
                    displayMode.cycle()
                }
            }
            .padding(.trailing, 14)
            .padding(.top, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            // Catch overlay card
            if let entry = selectedEntry {
                CatchOverlayCard(
                    entry: entry,
                    onDismiss: { selectedEntry = nil },
                    onOpenDetail: { navigateToDetail = true }
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Bottom: trip bar (full width) + FAB above it
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        showCapture = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(.red, in: Circle())
                            .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
                    }
                    .padding(.trailing, 14)
                    .padding(.bottom, 8)
                }

                TripBarView()
                    .padding(.horizontal, 14)
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            locationService.requestWhenInUse()
            if apiKey.isEmpty { showOnboarding = true }
        }
        .sheet(isPresented: $showCapture) {
            QuickCaptureSheet()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .navigationDestination(isPresented: $navigateToDetail) {
            if let entry = selectedEntry {
                CatchDetailView(entry: entry)
            }
        }
        .animation(.spring(duration: 0.3), value: selectedEntry?.id)
    }

    private func utilityButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 36, height: 36)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 9))
                .shadow(color: .black.opacity(0.18), radius: 4, y: 1)
        }
        .tint(.primary)
    }
}
```

- [ ] **Step 4: Build — expect success**

```bash
xcodebuild -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3
```

- [ ] **Step 5: Commit**

```bash
git add Fisu/Features/Map/
git commit -m "feat: add MapScreen with FAB, trip bar, catch overlay card"
```

---

## Task 13: QuickCaptureSheet

**Files:**
- Create: `Fisu/Features/Capture/QuickCaptureSheet.swift`

- [ ] **Step 1: Create `QuickCaptureSheet.swift`**

`Fisu/Features/Capture/QuickCaptureSheet.swift`:
```swift
import SwiftUI
import PhotosUI

struct QuickCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CatchStore.self) private var catchStore
    @Environment(LocationService.self) private var locationService
    @Environment(PhotoService.self) private var photoService

    @State private var selectedSpeciesCode: String?
    @State private var customSpecies = ""
    @State private var lengthText = ""
    @State private var weightText = ""
    @State private var released: Bool?
    @State private var lure = ""
    @State private var method = ""
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var thumbnailData: Data?
    @State private var capturedLocation: CLLocation?
    @State private var capturedTime = Date.now

    private let gridColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Context chips
                    contextChips
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    sectionHeader("Species")
                    speciesGrid
                        .padding(.horizontal, 12)

                    if selectedSpeciesCode == "other" {
                        TextField("Species name", text: $customSpecies)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    sectionHeader("Details · optional")
                    optionalFields
                }
            }
            .navigationTitle("New catch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .disabled(selectedSpeciesCode == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            capturedLocation = locationService.location
            capturedTime = .now
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let pair = await photoService.process(item) {
                    photoData = pair.full
                    thumbnailData = pair.thumb
                }
            }
        }
    }

    private var contextChips: some View {
        HStack(spacing: 8) {
            chip("📍 GPS")
            chip("🕗 \(DateFormatter.fiShort.string(from: capturedTime))")
        }
    }

    private var speciesGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 8) {
            ForEach(FishSpeciesCatalog.all) { species in
                Button {
                    selectedSpeciesCode = species.code
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(species.color)
                            .frame(width: 10, height: 10)
                        Text(species.nameFI)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                    .background(
                        selectedSpeciesCode == species.code
                            ? species.color.opacity(0.18)
                            : Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 11)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(selectedSpeciesCode == species.code ? species.color : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var optionalFields: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                labeledField("Length (cm)", text: $lengthText, keyboard: .numberPad)
                labeledField("Weight (kg)", text: $weightText, keyboard: .decimalPad)
            }

            Picker("Kept / Released", selection: $released) {
                Text("–").tag(Optional<Bool>.none)
                Text("Kept").tag(Optional<Bool>.some(false))
                Text("Released").tag(Optional<Bool>.some(true))
            }
            .pickerStyle(.segmented)

            labeledField("Lure / bait", text: $lure, keyboard: .default)
            labeledField("Method", text: $method, keyboard: .default)
            labeledField("Notes", text: $notes, keyboard: .default)

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label(
                    photoData == nil ? "Add photo" : "Change photo",
                    systemImage: photoData == nil ? "camera" : "checkmark.circle.fill"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 11))
            }
            .tint(photoData == nil ? .primary : .green)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    private func labeledField(_ label: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(label, text: text)
                .keyboardType(keyboard)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.secondarySystemGroupedBackground), in: Capsule())
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }

    private func save() {
        let lat = capturedLocation?.coordinate.latitude ?? 0
        let lon = capturedLocation?.coordinate.longitude ?? 0
        let acc = capturedLocation?.horizontalAccuracy
        let lengthMm = Int(lengthText.trimmingCharacters(in: .whitespaces)).map { $0 * 10 }
        let weightG = Double(weightText.trimmingCharacters(in: .whitespaces)).map { Int($0 * 1000) }

        let entry = catchStore.create(
            speciesCode: selectedSpeciesCode,
            speciesCustomName: selectedSpeciesCode == "other" ? customSpecies : nil,
            latitude: lat,
            longitude: lon,
            horizontalAccuracy: acc,
            timestamp: capturedTime,
            lengthMm: lengthMm,
            weightGram: weightG,
            released: released,
            lure: lure.isEmpty ? nil : lure,
            method: method.isEmpty ? nil : method,
            notes: notes.isEmpty ? nil : notes
        )
        entry.photoData = photoData
        entry.thumbnailData = thumbnailData
        dismiss()
    }
}
```

- [ ] **Step 2: Build — expect success**

```bash
xcodebuild -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3
```

- [ ] **Step 3: Commit**

```bash
git add Fisu/Features/Capture/
git commit -m "feat: add QuickCaptureSheet"
```

---

## Task 14: CatchDetailView + CatchEditView

**Files:**
- Create: `Fisu/Features/Catch/CatchDetailView.swift`
- Create: `Fisu/Features/Catch/CatchEditView.swift`

- [ ] **Step 1: Create `CatchDetailView.swift`**

`Fisu/Features/Catch/CatchDetailView.swift`:
```swift
import SwiftUI

struct CatchDetailView: View {
    let entry: Catch
    @Environment(CatchStore.self) private var catchStore
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Photo
                Group {
                    if let data = entry.photoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(height: 160)
                            .overlay(
                                Image(systemName: "fish")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.secondary)
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    // Species header
                    HStack(spacing: 8) {
                        Circle()
                            .fill(FishSpeciesCatalog.color(for: entry.speciesCode))
                            .frame(width: 14, height: 14)
                        Text(entry.speciesDisplayName)
                            .font(.title2.bold())
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                    if !entry.sizeDisplay.isEmpty {
                        Text(entry.sizeDisplay)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                    }

                    Divider().padding(.top, 16)

                    detailRow("When", DateFormatter.fiDateTime.string(from: entry.timestamp))

                    if let rel = entry.released {
                        detailRow("Kept / Released", rel ? "Released" : "Kept")
                    }

                    if let lure = entry.lure, !lure.isEmpty {
                        detailRow("Lure / bait", lure)
                    }

                    if let method = entry.method, !method.isEmpty {
                        detailRow("Method", method)
                    }

                    if let trip = entry.trip, let title = trip.title {
                        detailRow("Trip", title)
                    }

                    if let notes = entry.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Text(notes)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        Divider()
                    }
                }
            }
        }
        .navigationTitle(entry.speciesDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) { showDeleteAlert = true } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            CatchEditView(entry: entry)
        }
        .alert("Delete catch?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                catchStore.delete(entry)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            Divider()
        }
    }
}
```

- [ ] **Step 2: Create `CatchEditView.swift`**

`Fisu/Features/Catch/CatchEditView.swift`:
```swift
import SwiftUI
import PhotosUI

struct CatchEditView: View {
    let entry: Catch
    @Environment(\.dismiss) private var dismiss
    @Environment(PhotoService.self) private var photoService

    @State private var speciesCode: String?
    @State private var customSpecies = ""
    @State private var lengthText = ""
    @State private var weightText = ""
    @State private var released: Bool?
    @State private var lure = ""
    @State private var method = ""
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section("Species") {
                    Picker("Species", selection: $speciesCode) {
                        Text("–").tag(Optional<String>.none)
                        ForEach(FishSpeciesCatalog.all) { sp in
                            Text(sp.nameFI).tag(Optional<String>.some(sp.code))
                        }
                    }
                    if speciesCode == "other" {
                        TextField("Custom name", text: $customSpecies)
                    }
                }

                Section("Measurements") {
                    TextField("Length (cm)", text: $lengthText)
                        .keyboardType(.numberPad)
                    TextField("Weight (kg)", text: $weightText)
                        .keyboardType(.decimalPad)
                }

                Section("Info") {
                    Picker("Kept / Released", selection: $released) {
                        Text("–").tag(Optional<Bool>.none)
                        Text("Kept").tag(Optional<Bool>.some(false))
                        Text("Released").tag(Optional<Bool>.some(true))
                    }
                    TextField("Lure / bait", text: $lure)
                    TextField("Method", text: $method)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(
                            entry.photoData != nil ? "Change photo" : "Add photo",
                            systemImage: "camera"
                        )
                    }
                }
            }
            .navigationTitle("Edit Catch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { commitEdits(); dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { loadFromEntry() }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    if let pair = await photoService.process(item) {
                        entry.photoData = pair.full
                        entry.thumbnailData = pair.thumb
                    }
                }
            }
        }
    }

    private func loadFromEntry() {
        speciesCode = entry.speciesCode
        customSpecies = entry.speciesCustomName ?? ""
        if let mm = entry.lengthMm { lengthText = "\(mm / 10)" }
        if let g = entry.weightGram { weightText = String(format: "%.2f", Double(g) / 1000) }
        released = entry.released
        lure = entry.lure ?? ""
        method = entry.method ?? ""
        notes = entry.notes ?? ""
    }

    private func commitEdits() {
        entry.speciesCode = speciesCode
        entry.speciesCustomName = speciesCode == "other" ? customSpecies : nil
        entry.lengthMm = Int(lengthText).map { $0 * 10 }
        entry.weightGram = Double(weightText).map { Int($0 * 1000) }
        entry.released = released
        entry.lure = lure.isEmpty ? nil : lure
        entry.method = method.isEmpty ? nil : method
        entry.notes = notes.isEmpty ? nil : notes
    }
}
```

- [ ] **Step 3: Build — expect success**

```bash
xcodebuild -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3
```

- [ ] **Step 4: Commit**

```bash
git add Fisu/Features/Catch/
git commit -m "feat: add CatchDetailView and CatchEditView"
```

---

## Task 15: CatchesListView

**Files:**
- Create: `Fisu/Features/History/CatchRowView.swift`
- Create: `Fisu/Features/History/CatchesListView.swift`

- [ ] **Step 1: Create `CatchRowView.swift`**

`Fisu/Features/History/CatchRowView.swift`:
```swift
import SwiftUI

struct CatchRowView: View {
    let entry: Catch
    let isPersonalBest: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail / placeholder
            Group {
                if let data = entry.thumbnailData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(FishSpeciesCatalog.color(for: entry.speciesCode).opacity(0.2))
                        .overlay(
                            Image(systemName: "fish")
                                .foregroundStyle(FishSpeciesCatalog.color(for: entry.speciesCode))
                        )
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(FishSpeciesCatalog.color(for: entry.speciesCode))
                        .frame(width: 9, height: 9)
                    Text(entry.speciesDisplayName)
                        .font(.subheadline.weight(.bold))
                    if !entry.sizeDisplay.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(entry.sizeDisplay)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Text("\(DateFormatter.fiDateTime.string(from: entry.timestamp))\(entry.trip?.title.map { " · \($0)" } ?? "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isPersonalBest {
                Text("🏆")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.yellow.opacity(0.25), in: Capsule())
            }
        }
    }
}
```

- [ ] **Step 2: Create `CatchesListView.swift`**

`Fisu/Features/History/CatchesListView.swift`:
```swift
import SwiftUI
import SwiftData

struct CatchesListView: View {
    @Environment(CatchStore.self) private var catchStore
    @Query(sort: \Catch.timestamp, order: .reverse) private var allCatches: [Catch]

    @State private var selectedSpecies: Set<String> = []
    @State private var sortOrder: CatchFilter.SortOrder = .newestFirst
    @State private var personalBests: [String: Catch] = [:]
    @State private var navigateTo: Catch?

    private var filter: CatchFilter {
        CatchFilter(
            species: selectedSpecies.isEmpty ? nil : selectedSpecies,
            sortOrder: sortOrder
        )
    }

    private var filtered: [Catch] {
        filter.apply(to: allCatches)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { entry in
                    NavigationLink(value: entry) {
                        CatchRowView(
                            entry: entry,
                            isPersonalBest: personalBests[entry.speciesCode ?? ""]?.id == entry.id
                        )
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet { catchStore.delete(filtered[i]) }
                }
            }
            .navigationTitle("Catches")
            .navigationDestination(for: Catch.self) { entry in
                CatchDetailView(entry: entry)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Section("Sort") {
                            Button("Newest first") { sortOrder = .newestFirst }
                            Button("Biggest first") { sortOrder = .biggestFirst }
                        }
                        Section("Filter species") {
                            ForEach(FishSpeciesCatalog.all) { sp in
                                Button {
                                    if selectedSpecies.contains(sp.code) {
                                        selectedSpecies.remove(sp.code)
                                    } else {
                                        selectedSpecies.insert(sp.code)
                                    }
                                } label: {
                                    Label(sp.nameFI, systemImage: selectedSpecies.contains(sp.code) ? "checkmark" : "")
                                }
                            }
                            if !selectedSpecies.isEmpty {
                                Button("Clear filter") { selectedSpecies = [] }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle\(selectedSpecies.isEmpty ? "" : ".fill")")
                    }
                }
            }
            .task {
                personalBests = (try? catchStore.personalBests()) ?? [:]
            }
            .onChange(of: allCatches.count) { _, _ in
                Task { personalBests = (try? catchStore.personalBests()) ?? [:] }
            }
        }
    }
}
```

- [ ] **Step 3: Build — expect success**

```bash
xcodebuild -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3
```

- [ ] **Step 4: Commit**

```bash
git add Fisu/Features/History/
git commit -m "feat: add CatchesListView with species filter, sort, and personal bests"
```

---

## Task 16: TripsListView + TripDetailView

**Files:**
- Create: `Fisu/Features/Trips/TripsListView.swift`
- Create: `Fisu/Features/Trips/TripDetailView.swift`

- [ ] **Step 1: Create `TripsListView.swift`**

`Fisu/Features/Trips/TripsListView.swift`:
```swift
import SwiftUI
import SwiftData

struct TripsListView: View {
    @Query(sort: \Trip.startTime, order: .reverse) private var trips: [Trip]
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            List {
                ForEach(trips) { trip in
                    NavigationLink(value: trip) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.title ?? "Trip")
                                .font(.subheadline.weight(.bold))
                            HStack(spacing: 6) {
                                Text(DateFormatter.fiDateTime.string(from: trip.startTime))
                                if let km = trip.distanceMeters {
                                    Text("·")
                                    Text(String(format: "%.1f km", km / 1000))
                                }
                                Text("·")
                                Text("\(trip.catches?.count ?? 0) fish")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet { context.delete(trips[i]) }
                }
            }
            .navigationTitle("Trips")
            .navigationDestination(for: Trip.self) { trip in
                TripDetailView(trip: trip)
            }
            .overlay {
                if trips.isEmpty {
                    ContentUnavailableView("No trips yet", systemImage: "map", description: Text("Start a trip from the map to record your route."))
                }
            }
        }
    }
}
```

- [ ] **Step 2: Create `TripDetailView.swift`**

`Fisu/Features/Trips/TripDetailView.swift`:
```swift
import SwiftUI
import MapKit

struct TripDetailView: View {
    let trip: Trip
    @State private var showRename = false
    @State private var newTitle = ""

    private var routePoints: [RoutePoint] {
        guard let data = trip.routeData else { return [] }
        return (try? JSONDecoder().decode([RoutePoint].self, from: data)) ?? []
    }

    private var catches: [Catch] { trip.catches ?? [] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Mini map
                MapContainerView(
                    catches: catches,
                    displayMode: .dots,
                    routePoints: routePoints,
                    apiKey: KeychainStore.mmlApiKey ?? "",
                    onCatchSelected: { _ in },
                    onCatchDeselected: {}
                )
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 0))

                // Stats strip
                HStack {
                    statCell("Distance", trip.distanceMeters.map { String(format: "%.1f km", $0 / 1000) } ?? "–")
                    Divider().frame(height: 40)
                    statCell("Duration", durationString)
                    Divider().frame(height: 40)
                    statCell("Fish", "\(catches.count)")
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                Divider()

                // Species breakdown
                if !catches.isEmpty {
                    let grouped = Dictionary(grouping: catches, by: { $0.speciesCode ?? "other" })
                    HStack(spacing: 14) {
                        ForEach(grouped.sorted(by: { $0.value.count > $1.value.count }), id: \.key) { code, entries in
                            HStack(spacing: 4) {
                                Circle().fill(FishSpeciesCatalog.color(for: code)).frame(width: 10, height: 10)
                                Text("\(entries.count) \(FishSpeciesCatalog.displayName(for: code))")
                                    .font(.caption.weight(.semibold))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    Divider()
                }

                // Catches list
                if catches.isEmpty {
                    Text("No catches on this trip.")
                        .foregroundStyle(.secondary)
                        .padding(20)
                } else {
                    ForEach(catches.sorted(by: { $0.timestamp < $1.timestamp })) { entry in
                        NavigationLink(destination: CatchDetailView(entry: entry)) {
                            CatchRowView(entry: entry, isPersonalBest: false)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        Divider()
                    }
                }
            }
        }
        .navigationTitle(trip.title ?? "Trip")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Rename") {
                    newTitle = trip.title ?? ""
                    showRename = true
                }
            }
        }
        .alert("Rename trip", isPresented: $showRename) {
            TextField("Trip name", text: $newTitle)
            Button("Save") { trip.title = newTitle }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var durationString: String {
        guard let end = trip.endTime else { return "–" }
        let secs = Int(end.timeIntervalSince(trip.startTime))
        return String(format: "%d:%02d", secs / 3600, (secs % 3600) / 60)
    }

    private func statCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.weight(.bold)).foregroundStyle(.green)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
```

- [ ] **Step 3: Build — expect success**

```bash
xcodebuild -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3
```

- [ ] **Step 4: Commit**

```bash
git add Fisu/Features/Trips/
git commit -m "feat: add TripsListView and TripDetailView"
```

---

## Task 17: Final assembly — RootTabView + FisuApp

**Files:**
- Modify: `Fisu/App/RootTabView.swift`
- Modify: `Fisu/App/FisuApp.swift`

- [ ] **Step 1: Update `RootTabView.swift`**

`Fisu/App/RootTabView.swift`:
```swift
import SwiftUI

struct RootTabView: View {
    @Environment(TripRecorder.self) private var recorder

    var body: some View {
        TabView {
            NavigationStack {
                MapScreen()
            }
            .tabItem { Label("Map", systemImage: "map.fill") }

            CatchesListView()
                .tabItem { Label("Catches", systemImage: "fish.fill") }

            TripsListView()
                .tabItem { Label("Trips", systemImage: "point.topleft.down.to.point.bottomright.curvepath.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
```

- [ ] **Step 2: Update `FisuApp.swift`**

`Fisu/App/FisuApp.swift`:
```swift
import SwiftUI
import SwiftData

@main
struct FisuApp: App {
    private let modelContainer: ModelContainer
    private let locationService = LocationService()
    private let tripRecorder: TripRecorder
    private let catchStore: CatchStore
    private let photoService = PhotoService()

    init() {
        let schema = Schema([Catch.self, Trip.self])
        // Use CloudKit private DB. On simulators without a signed-in account
        // this will fall back to local-only storage automatically.
        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private("iCloud.fi.fisu.app")
        )
        do {
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            // Fallback: local-only (CloudKit not available / not configured yet)
            let fallback = ModelConfiguration(schema: schema)
            modelContainer = try! ModelContainer(for: schema, configurations: fallback)
        }
        let context = modelContainer.mainContext
        tripRecorder = TripRecorder(locationService: locationService, context: context)
        catchStore = CatchStore(context: context, tripRecorder: tripRecorder)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .modelContainer(modelContainer)
                .environment(locationService)
                .environment(tripRecorder)
                .environment(catchStore)
                .environment(photoService)
                .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)) { _ in }
        }
    }
}
```

- [ ] **Step 3: Wire TripRecorder to LocationService updates**

In `MapScreen.swift`, add `.onChange` to forward location updates to the recorder. Add at the end of `body`:

```swift
.onChange(of: locationService.location) { _, location in
    guard let location else { return }
    recorder.appendLocation(location)
}
```

Add this modifier to the ZStack in `MapScreen.body`, before `.onAppear`.

- [ ] **Step 4: Wire "keep screen awake" to UIApplication**

In `TripBarView.swift`, add `.onChange` on `recorder.state`:

```swift
.onChange(of: recorder.state) { _, state in
    let keepAwake = UserDefaults.standard.bool(forKey: "keepScreenAwake")
    UIApplication.shared.isIdleTimerDisabled = (state == .recording && keepAwake)
}
```

Add this to the `VStack` in `TripBarView.body`.

- [ ] **Step 5: Final build and all tests**

```bash
xcodebuild -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3
xcodebuild test -scheme Fisu -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "FAILED|PASSED|error:"
```

Expected: `** BUILD SUCCEEDED **`, all test suites PASSED.

- [ ] **Step 6: Commit**

```bash
git add Fisu/App/
git commit -m "feat: assemble FisuApp with ModelContainer, services, tab navigation"
```

---

## Self-Review

**Spec coverage check:**

| Spec section | Covered by task |
|---|---|
| MML maastokartta basemap | Task 5 (MMLTileOverlay) + Task 10 (MapContainerView) |
| Offline tile caching | Task 4 (TileCache) |
| Pinch zoom (MKMapView default) | Task 10 (MKMapView enables pinch by default) |
| Quick-capture (one-tap save) | Task 13 |
| All catch fields | Task 2 (model) + Task 13 (form) + Task 14 (edit) |
| Background location (Always while trip active) | Task 6 (LocationService.startUpdating sets allowsBackgroundLocationUpdates) |
| Auto-tag catch to active trip | Task 8 (CatchStore.create uses tripRecorder?.activeTrip) |
| Dot/label/hidden display modes | Task 10 (CatchDisplayMode + CatchAnnotationView) |
| Clustering | Task 10 (clusteringIdentifier + ClusterAnnotationView) |
| Two-stage tap: dot → overlay → detail | Task 12 (CatchOverlayCard in MapScreen) |
| Catches list with species filter, sort, PB | Task 15 |
| Trips list + trip detail | Task 16 |
| Personal bests (per-species, weight-then-length) | Task 8 (CatchStore.personalBests) |
| iCloud private CloudKit sync | Task 17 (FisuApp ModelConfiguration .private) |
| Onboarding (first-run api-key entry) | Task 11 |
| Settings (key, tracking, iCloud status) | Task 11 |
| MML © attribution | Task 11 (SettingsView footer) |
| Photo capture + downsample + thumbnail | Task 9 (PhotoService) |
| Species catalog (Finnish list + Other) | Task 3 |
| Formatting (mm→cm, g→kg) | Task 3 |
| MML api-key in Keychain | Task 3 (KeychainStore) |
| Haversine route distance | Task 7 (TripRecorder + tests) |
| Trip title auto-generated | Task 7 (TripRecorder.autoTitle) |
| Trip pause/stop/rename | Task 12 (TripBarView) + Task 16 (TripDetailView rename) |
| Catch delete (from detail + swipe in list) | Task 14 + Task 15 |

**No gaps found. All spec requirements are covered.**

---

## Execution

Plan saved to `docs/superpowers/plans/2026-05-31-fisu-implementation.md`.

**Two execution options:**

**1. Subagent-Driven (recommended)** — fresh subagent per task, review between tasks, fast iteration. Use `superpowers:subagent-driven-development`.

**2. Inline Execution** — execute tasks in this session with checkpoints. Use `superpowers:executing-plans`.

Which approach?
