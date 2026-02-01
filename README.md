# WalkyTrails

A simple iOS app to log dog walks: track duration and distance, mark pee/poop spots on a map, and review your walk history.

## Features

- **Start a walk** – Tap Start Walk, then walk. Duration and GPS distance update live.
- **Map** – See your path and your position. Tap Pee or Poop to drop a marker at your current location.
- **Dog profile** – One profile (name, breed, optional photo). Set up on first launch; edit or delete anytime from Home.
- **History** – Saved walks with duration, distance, and events. Tap a walk to see the route and pee/poop markers on the map.
- **Local only** – No account, no backend. Data stays on device (UserDefaults).

## Requirements

- Xcode 15+
- iOS 17.0+
- Device or Simulator with location (for distance and map)

## How to run

1. Open the project in Xcode:
   ```
   open WalkyTrails/WalkyTrails.xcodeproj
   ```
2. Select a simulator or device (e.g. iPhone 16).
3. Run (⌘R).

**Simulator:** To test GPS and the map, set a location in the Simulator menu: **Features → Location** (e.g. City Run, Freeway Drive, or a custom GPX).

## Project layout

- **WalkyTrails/WalkyTrails/** – App target (SwiftUI): views, models, `WalkStore`, `DogProfileStore`, `LocationManager`.
- **docs/** – App icon, App Store submission, map strategy, launch screen, privacy page setup.

## Privacy

- Location is used only while a walk is in progress (distance and route). See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) and [docs/APP_STORE_SUBMISSION.md](docs/APP_STORE_SUBMISSION.md) for submission details.

## License

Private / personal use.
