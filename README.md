# Fisu

An iOS fishing catch tracker built with SwiftUI and SwiftData, using MML (Maanmittauslaitos) topographic maps.

## Features

- **Trip tracking** — start and stop fishing trips with GPS recording
- **Catch logging** — quick-capture sheet to log catches with species, weight, and location
- **Topo maps** — MML topographic tile overlay (zoom up to level 18) over Apple Maps
- **Catch visualization** — catches displayed as map annotations with cluster support
- **History** — browse past trips and catches
- **Offline tiles** — tile caching for use in areas with poor connectivity

## Tech Stack

- Swift 6.2, SwiftUI, SwiftData
- iOS 26+ deployment target
- `xcodegen` via `project.yml`
- MML WMTS tile overlay via `MKTileOverlay`
- CoreLocation for GPS tracking

## Requirements

- Xcode 26+
- `xcodegen` (`brew install xcodegen`)

## Setup

```bash
git clone https://github.com/sepanniemi/fisu
cd fisu
xcodegen generate
open Fisu.xcodeproj
```

Build and run on a device or simulator. Location permissions are required for map centering and trip GPS tracking.

## Project Structure

```
Fisu/
├── App/            # Entry point, app lifecycle
├── Features/
│   ├── Capture/    # Quick-capture catch sheet
│   ├── Catches/    # Catch list views
│   ├── History/    # Trip history
│   ├── Map/        # Map screen and trip overlay
│   ├── Settings/   # App settings
│   └── Trips/      # Trip management
├── Map/            # MKMapView wrapper, MML tile overlay, annotations
├── Models/         # SwiftData models
├── Location/       # GPS / CoreLocation
├── Persistence/    # SwiftData container setup
└── Services/       # Shared services
```

## License

MIT
