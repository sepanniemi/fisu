# Fisu — Finnish Fishing Catch Tracker — Design Spec

- **Date:** 2026-05-31
- **Status:** Approved design, ready for implementation planning
- **Platform:** iOS 26+ (Xcode 26.3, Swift 6.2)

---

## 1. Overview & Goals

Fisu is an iOS app for logging fishing catches on an official Finnish topographic
map. The primary use case is **trolling on a lake** (logging catches fast, one-handed,
while moving), with secondary support for **casting from shore / a river**. Each catch
is pinned to the GPS coordinate where it was caught, with species, optional
measurements, an optional photo, and a timestamp. Trips (GPS routes) can be recorded
and drawn on the map. Catches are browsable as a filterable list and viewable on the map.

**Design principles**
- The map is the hero; on-the-water actions must be big, obvious, one-handed.
- The map must be zoomable using pinch zoom
- Logging a hooked fish is the most time-critical action → one-tap save.
- The map must stay readable even with many catches.
- No custom backend: per-user data lives locally and syncs to each user's own iCloud.

---

## 2. Users & Distribution

- **Audience:** a small group (the developer + a few fishing buddies) running the same
  build. **Each person keeps their own private data** — no data sharing between users.
- **Distribution:** one shared build (e.g. TestFlight or ad-hoc via the developer
  account). No public App Store product, no user accounts.
- **Sync/identity:** each user's data syncs to **their own private iCloud** (CloudKit
  private database) tied to their Apple ID. No server to operate.

---

## 3. Scope

**In scope (v1)**
- MML `maastokartta` topographic basemap with integrated depth contours/points.
- Offline tile caching of viewed areas.
- Pinch Zooming
- Quick-capture catch logging (species + GPS + time in one tap; optional details).
- Catch fields: species, length (opt), weight (opt), one photo (opt), date/time,
  kept/released (opt), lure/bait (opt), method (opt), notes (opt).
- Manual-start/stop GPS trip recording with background ("Always") tracking while active.
- Auto-tagging catches to the active trip.
- Catch display on map: Dots (default, colour-by-species) / Labels / Hidden, with
  automatic clustering and a tap-overlay → full-detail flow.
- Catches history list: filter by date range, by species, sort/highlight personal bests.
- Trips list and trip detail (route + stats + its catches).
- Settings + first-run onboarding for the user's MML api-key.
- iCloud (CloudKit) private sync of catches & trips.

**Out of scope (v1, candidates for later)**
- Sharing catches between users; social/leaderboards.
- Additional basemaps (`taustakartta`, `ortokuva`) — trivial to add later (same API).
- Auto-detected trips; always-on tracking.
- Sonar/fish-finder integration; weather/water-temp auto-capture.
- Multiple photos per catch.
- Manual data export (iCloud sync covers backup).
- Imperial units.

---

## 4. Platform & Tech Stack

- **Language/UI:** Swift 6.2 (strict concurrency), SwiftUI.
- **Persistence + sync:** SwiftData (`@Model`) with CloudKit **private** database.
- **Map:** UIKit `MKMapView` wrapped in a SwiftUI `UIViewRepresentable` (required — see §5).
- **Location:** CoreLocation (`CLLocationManager`).
- **Photos:** PhotosUI (`PhotosPicker` for library; camera capture for live photos).
- **Tests:** Swift Testing.
- **Project generation:** `xcodegen` from `project.yml`.
- **Min iOS:** 26 (single shared build; no need to support older).

---

## 5. Architecture

Everything is pure SwiftUI **except one isolated UIKit island** for the map. Rendering the
MML WMTS basemap needs a custom `MKTileOverlay` (`canReplaceMapContent = true`), and a
readable catch display needs MapKit annotation **clustering** (`clusteringIdentifier`).
SwiftUI's native `Map` exposes neither, so the map is built on `MKMapView`. This is the
one deliberate UIKit dependency; it is wrapped behind a single representable.

### Module map

| Unit | Responsibility | Depends on |
|---|---|---|
| `ModelContainer` (SwiftData + CloudKit) | Local store + private-iCloud sync of `Catch` / `Trip` | CloudKit entitlement |
| `FishSpeciesCatalog` | Static curated species list (FI/EN name, colour, sort) — versioned in code, not synced | — |
| `MapContainerView` (`UIViewRepresentable`) | Hosts `MKMapView`; installs basemap; draws route polyline + catch annotations w/ clustering; exposes bindings (region, selection, display mode, isTracking, route) | MapKit, `MMLTileOverlay` |
| `MMLTileOverlay` (`MKTileOverlay`) | Builds MML WMTS tile URLs (api-key, z/x/y → tile matrix); replaces base content; disk-caches tiles | MapKit, Keychain (key) |
| `TileCache` | On-disk LRU cache of fetched tiles (size-capped) for offline viewing | — |
| `LocationService` (`@Observable`, `@MainActor`) | `CLLocationManager` wrapper: authorization, single fixes, streaming updates | CoreLocation |
| `TripRecorder` (`@Observable`) | Manual start/pause/stop; background route points; distance/duration; persists `Trip` | LocationService, ModelContainer |
| `CatchStore` (use-cases) | Create catch (current coord + time, auto-tag active trip), edit, delete; queries (filters, personal bests) | ModelContainer, TripRecorder |
| `PhotoService` | Camera/library capture, downsample, thumbnail generation | PhotosUI |
| `KeychainStore` | Stores the user's MML api-key | Security |
| Views | `RootTabView`, `MapScreen`, `QuickCaptureSheet`, `CatchDetailView`, `CatchesListView`, `TripsListView`, `TripDetailView`, `SettingsView`, `OnboardingView` | the services above |

### Core data flow — "log a catch"
Tap **＋** → `LocationService` provides the current coordinate + timestamp (captured
immediately) → `QuickCaptureSheet` collects species (+ optional fields) → `CatchStore`
creates a `Catch`, auto-linking `TripRecorder.activeTrip` if a trip is running → SwiftData
persists → CloudKit syncs in the background → SwiftUI `@Query` updates `MapScreen` and
`CatchesListView` automatically.

### Concurrency
UI and observable services are `@MainActor`. `CLLocationManager` delegate callbacks are
bridged to the main actor. Heavy work (image downsampling, route encode/decode, tile disk
I/O) runs off the main actor.

---

## 6. Data Model (SwiftData + CloudKit)

CloudKit-compatible rules followed throughout: every stored property is optional or has a
default; all relationships are optional; **no `@Attribute(.unique)`** constraints.

```swift
@Model final class Catch {
    var id: UUID = UUID()
    var timestamp: Date = Date.now            // date & time caught
    var latitude: Double = 0                  // pin location (GPS at capture)
    var longitude: Double = 0
    var horizontalAccuracy: Double?           // metres; surfaces a poor fix
    var speciesCode: String?                  // → FishSpeciesCatalog key
    var speciesCustomName: String?            // when speciesCode == "other"
    var lengthMm: Int?                         // optional; stored mm, shown cm
    var weightGram: Int?                       // optional; stored g, shown kg
    var released: Bool?                        // kept/released toggle (nil = unsaid)
    var lure: String?                          // lure / bait
    var method: String?                        // trolling / casting / jigging / …
    var notes: String?
    @Attribute(.externalStorage) var photoData: Data?      // one full photo, optional
    @Attribute(.externalStorage) var thumbnailData: Data?  // ~200px, for lists/markers
    var trip: Trip?                            // auto-tagged active trip (optional)
}

@Model final class Trip {
    var id: UUID = UUID()
    var title: String?                         // auto "31.5. troolaus" or user-named
    var startTime: Date = Date.now
    var endTime: Date?
    @Attribute(.externalStorage) var routeData: Data?   // compact encoded [RoutePoint]
    var distanceMeters: Double?                // cached
    @Relationship(inverse: \Catch.trip) var catches: [Catch]?
}

struct RoutePoint: Codable {   // packed into Trip.routeData, NOT separate records
    let lat: Double
    let lon: Double
    let t: Date
    let speed: Double?         // m/s, optional
}
```

**Deliberate decisions**
- **Route as one blob** (`routeData`, external storage), not thousands of per-point rows —
  a long trolling trip would otherwise create thousands of CloudKit records. Decode only
  when drawing/inspecting.
- **Species as a code into a code-side catalog**, not a synced table — the list can grow
  and localise via app updates with no sync churn; `"other"` falls back to free text.
- **Base units stored** (mm, g) for clean integer math; displayed metric (see §formatting).

**Formatting**
- Length: shown in **cm** (integer), e.g. `78 cm`.
- Weight: shown in **kg** with up to 2 decimals when ≥ 1 kg (e.g. `3.40 kg`), else grams
  (e.g. `240 g`).
- Dates: Finnish format `pp.kk.vvvv` + 24h time.

### FishSpeciesCatalog (initial)
Curated common Finnish species; extensible in code. Each entry: `code`, Finnish name,
English name, marker colour. The most common species get distinct colours; the long tail
shares a neutral palette; `other` is grey.

`ahven`/Perch, `hauki`/Pike, `kuha`/Zander, `taimen`/Brown trout, `kirjolohi`/Rainbow
trout, `lohi`/Salmon, `siika`/Whitefish, `made`/Burbot, `lahna`/Bream, `särki`/Roach,
`nieriä`/Arctic char, `harjus`/Grayling, `säyne`/Ide, `kuore`/Smelt, `other`/Other.

---

## 7. MML Basemap & Depth

- **Source:** MML Karttakuvapalvelu (open WMTS).
  Capabilities: `https://avoin-karttakuva.maanmittauslaitos.fi/avoin/wmts/1.0.0/WMTSCapabilities.xml`
- **Layer (v1):** `maastokartta`. The official **depth contours and depth points from
  SYKE + Traficom are already integrated into these tiles** (including smaller lakes), so
  no separate bathymetry source, reprojection, or licensing is needed.
- **Tile URL (RESTful):**
  `…/avoin/wmts/1.0.0/maastokartta/default/{TileMatrixSet}/{TileMatrix}/{TileRow}/{TileCol}.png`
  with the user's **`api-key`** as a query parameter.
- **Tile matrix set:** use `WGS84_Pseudo-Mercator` (EPSG:3857) so tiles align with
  MapKit/`MKTileOverlay`'s standard web-mercator `z/x/y` grid. The exact `TileMatrix`
  numbering will be confirmed against the capabilities document during implementation.
  (The user has confirmed the same key already works in another app.)
- **Attribution:** display **"© Maanmittauslaitos"** on the map per the open-data licence.
- **Offline caching:** `MMLTileOverlay` fetches tiles via a custom session and writes them
  to `TileCache` (on-disk, LRU, size-capped). Cached tiles serve when offline; uncached
  tiles in a dead zone render blank while routes & catches keep working. ("Cache visited
  areas" model — no explicit region pre-download in v1.)

---

## 8. Location & Trip Recording

- **Permissions:** request **When-In-Use** on first map appearance. **Escalate to
  "Always" only when the user starts a trip**, so the route keeps recording with the
  screen off / phone pocketed. Background location mode enabled; system blue indicator
  shown. Background updates and "Always" usage end when the trip stops (battery).
- **Trip lifecycle:** manual **Start → (Pause) → Stop**. While active, stream location
  (accuracy tuned for slow trolling speeds; distance/time filter to bound point density),
  append `RoutePoint`s, update live distance/duration. On Stop, encode `routeData`, cache
  `distanceMeters`, persist the `Trip`.
- **Standalone catch:** capture uses a single current fix; works with no trip active.
- **Auto-tag:** if a trip is active when a catch is saved, link `Catch.trip` to it.

---

## 9. Feature — Map Screen (hero / default tab)

- Full-bleed `maastokartta` basemap (with depth); current location (blue dot); route
  polyline while a trip is active; catch annotations per the display mode (§15).
- **＋ Catch:** compact round red FAB, bottom-right (thumb-reachable), just above the trip
  bar. Works with or without an active trip.
- **Trip bar:** full-width along the bottom.
  - No trip → **▶ Start trip** bar.
  - Trip active → collapsed bar shows live stats `● {km} · {h:mm} · {n} fish`; **tap to
    expand** → **⏸ Pause · ⏹ Stop · ✎ Note**. The FAB slides up to stay clear when expanded.
- **Top-right utility stack:** 📍 locate · 👁️ display mode (Dots → Labels → Hidden) ·
  ▦ filter (which catches are shown on the map: date range / species).

---

## 10. Feature — Quick-Capture Sheet

Tap **＋** → sheet slides up; **GPS + time captured immediately**.
- Header: title + **Save** in the top-right (true one-tap after picking a species).
- Context chips: `📍 GPS ±{m}`, `🕗 {time}`, and `● On trip` when a trip is active.
- **Species grid:** big colour-coded buttons (colours match the map dots) + `Other…`.
- **Details · optional (always visible below species):** Length, Weight, Kept/Released
  toggle, Lure/bait, Method, **📷 Add photo**, (Notes accessible here too).
- Large **Save catch** button at the bottom as well.
- Can save with **species only**; everything else is addable later from Catch Detail.

---

## 11. Feature — Catch Detail / Edit

- Large photo, species + size + weight, date/time, kept/released, lure & method, notes,
  a small map snippet with the pin, and a tappable link to its trip.
- **Edit** (same form as quick-capture — fill optional fields dockside), **Delete**,
  **Show on map**, and **Correct location** (drag the pin if the fix was poor).

---

## 12. Feature — Catches History (tab)

- Scrollable list; each row: thumbnail, species colour-dot, size/weight, date, and
  trip/shore context.
- **Filters:** date range; species (one or more).
- **Sort:** "Biggest" orders catches by size — by **weight**, falling back to **length**
  when weight is absent.
- **Personal best:** a 🏆 badge marks **each species' largest catch** (its personal best),
  using the same weight-then-length rule.
- Tapping a row opens Catch Detail (§11).

---

## 13. Feature — Trips (tab)

- List of recorded trips (date, title, distance, duration, catch count).
- **Trip detail:** route drawn on a mini map + its catch pins; stat strip (km · hours ·
  fish); species breakdown; the trip's catches list. Rename / delete trip.

---

## 14. Feature — Settings & Onboarding

- **Onboarding (first run):** prompt each user to paste **their own MML api-key**; until
  set, the map shows a friendly "Add your MML map key in Settings" empty state. Key stored
  in **Keychain**; never bundled or committed.
- **Settings**
  - **Map:** MML api-key field; required "© Maanmittauslaitos" attribution note. (Basemap
    is `maastokartta` only in v1.)
  - **Tracking:** GPS accuracy/interval; "keep screen awake while trip active" toggle.
  - **iCloud:** sync status ("Synced" / "Signed out — storing locally") + "Sync now".
  - **About:** version, attribution, licences. Units: metric (cm/kg), fixed.

---

## 15. Catch Display on the Map

- **Modes (👁️ cycles):**
  - **Dots (default):** small markers **colour-coded by species**.
  - **Labels:** species + date on each marker.
  - **Hidden:** only basemap + route.
- **Clustering:** when catches bunch up at low zoom they collapse into a green **count
  bubble**; tapping a cluster zooms in to split it (MapKit `clusteringIdentifier`).
- **Tap interaction (two-stage):**
  1. **Tap a dot** → compact overlay card (species + colour dot, date, length, weight)
     with an **✕** top-right to dismiss back to the bare map.
  2. **Tap the overlay** → full Catch Detail (§11).
- **Map filter (▦):** restricts which catches are shown on the map (date range / species).

---

## 16. Permissions & Error Handling

- **Location:** When-In-Use first; escalate to Always at trip start (see §8). Clear
  rationale strings.
- **No GPS fix at capture:** save with manual pin placement + retry; store
  `horizontalAccuracy` so a poor fix is visible and correctable.
- **Offline tiles:** cached tiles serve; uncached tiles render blank; routes/catches
  unaffected.
- **iCloud signed out / unavailable:** app works fully local; sync resumes when signed in;
  a quiet Settings banner explains the state. CloudKit default last-writer-wins is fine for
  single-user-per-account data.
- **Missing/invalid/expired MML key:** map empty-state / "Map key error — check your MML
  key" message routed to Settings.
- **Camera permission denied:** allow library picker (PhotosPicker needs no permission);
  explain how to enable the camera.

---

## 17. Testing Strategy

TDD with **Swift Testing** on pure logic (cheap, where bugs hide):
- WMTS tile math: `z/x/y` ↔ MML tile-matrix identifiers and tile bbox.
- Route encode/decode; distance (Haversine) and duration calculations.
- `FishSpeciesCatalog` lookups and `"other"` handling.
- Catch filtering (date range, species), sorting, and personal-best queries.
- Unit formatting (mm→cm, g→kg) and date formatting.
- Trip auto-tag logic (catch ↔ active trip).

Map rendering, CloudKit sync, and background location are verified by manual/integration
checks, not unit tests.

---

## 18. Project Structure & Tooling

- **`xcodegen`** from `project.yml` (clean repo, reproducible shared build).
- Suggested groups: `App/`, `Models/`, `Persistence/`, `Map/` (representable, overlay,
  cache), `Location/`, `Features/{Map,Catch,History,Trips,Settings,Onboarding}/`,
  `Services/`, `Resources/`.
- **Entitlements:** CloudKit (private DB) + remote notifications; background location mode.
- **Info.plist:** `NSLocationWhenInUseUsageDescription`,
  `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSCameraUsageDescription`,
  `UIBackgroundModes: [location]`.
- **Secrets/ignore:** MML api-key is entered per-user at runtime (Keychain) — not in the
  repo. `.gitignore` should include build output, `*.xcodeproj` (generated), `.superpowers/`,
  and any local `*.xcconfig` holding secrets.
- **Swift 6** strict concurrency; `@MainActor` services; `@Observable` view models.

---

## 19. Decision Log

| Topic | Decision |
|---|---|
| Audience | Small group; each keeps own private data; one shared build |
| Offline maps | Auto-cache viewed tiles (no region pre-download) |
| Backup/sync | iCloud private sync via CloudKit; no backend |
| Route tracking | Manual start/stop (+ pause); Always location only while active |
| Basemap | MML `maastokartta` only |
| Depth | Comes integrated in `maastokartta` tiles (SYKE + Traficom) — no extra source |
| Species entry | Curated Finnish list + free-text "Other" |
| Logging flow | Quick-capture, fill later; one-tap save with species only |
| Trip ↔ catch | Auto-tag to active trip; standalone otherwise |
| Extra catch fields | Kept/released, lure/bait & method, notes |
| History filters | Date range, species, personal-bests/sort-by-size |
| Persistence stack | SwiftData + CloudKit |
| Navigation | Four tabs: Map · Catches · Trips · Settings |
| Map actions | Round ＋ FAB bottom-right; full-width trip bar, collapsed→expand for Pause/Stop/Note |
| Marker default | Dots, colour-by-species; 👁️ toggles Dots→Labels→Hidden; auto-cluster |
| Catch tap | Tap dot → overlay (species/date/length/weight, ✕ to close) → tap overlay → full detail |
| Quick-capture optional fields | Always visible below species grid |
| Background location | Always, only while a trip records |
| Api-key | Each user enters their own (Keychain); not bundled |

---

## 20. Open Questions / Future

- Confirm exact MML `TileMatrix` numbering vs MapKit `z` at implementation.
- Later: extra basemaps, sharing, sonar import, multi-photo, region pre-download.
