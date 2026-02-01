# WalkyTrails – Project Context

## Overview

WalkyTrails is an iOS app for logging dog walks: start a walk, track duration (and optional events like pee/poop), end the walk, see a summary, and save it to history. All data is stored locally on device (no backend for v1). Built with **Swift** and **SwiftUI**, same publishing flow as FlashRead.

## Tech Stack

- **Platform:** iOS (iPhone, iPad)
- **Language:** Swift
- **UI:** SwiftUI
- **Storage:** UserDefaults (v1)
- **Bundle ID:** com.cyrus.WalkyTrails
- **Deployment target:** iOS 17.0+

## App Flow (v1 MVP)

1. **Home** – “Start Walk” button, “History” link.
2. **During walk** – Live timer, optional Pee/Poop buttons, “End Walk”.
3. **Summary** – Duration, optional distance, list of events; Save or Discard.
4. **History** – List of saved walks; tap a walk to see detail (duration, events).

## Core Features (v1)

- Start / stop a walk.
- Live duration (timer) while walking.
- Optional events: Pee, Poop (timestamp only for v1).
- Post-walk summary with Save or Discard.
- Walk history list; tap to open walk detail (duration, events).
- All data local (UserDefaults); no login, no backend.

## Out of Scope (v1)

- No login, no Supabase, no backend.
- No map, no route planning, no shared routes.
- No community, weather, gamification, POIs, or AI.

## Project Structure (Swift)

```
walkyTrails/
├── WalkyTrails/
│   ├── WalkyTrails.xcodeproj
│   └── WalkyTrails/
│       ├── WalkyTrailsApp.swift
│       ├── ContentView.swift
│       ├── WalkStore.swift
│       ├── Models/
│       │   └── Walk.swift
│       ├── Views/
│       │   ├── HomeView.swift
│       │   ├── DuringWalkView.swift
│       │   ├── WalkSummaryView.swift
│       │   ├── WalkHistoryView.swift
│       │   └── WalkDetailView.swift
│       └── Assets.xcassets/
└── docs/
    ├── CONTEXT.md          (this file)
    ├── ANALYSIS_AND_PLAN.md
    └── BUILD_TROUBLESHOOTING.md
```

## Future (post–v1)

- Optional: one dog profile (name, breed, photo) stored locally.
- Optional: map showing recorded path for a walk.
- Optional: distance from GPS.
- Later: Supabase (auth, sync), Mapbox, shared routes, community (see TailTrails CONTEXT.md for ideas).

## Publishing (iOS)

Same playbook as FlashRead:

1. Privacy policy (hosted URL).
2. App Store listing: name, subtitle, description, keywords, screenshots, icon.
3. Archive in Xcode → Distribute App → App Store Connect.
4. Submit for review; address feedback; release.

## Related Docs

- **ANALYSIS_AND_PLAN.md** – How we chose Swift, MVP scope, phased plan.
- **BUILD_TROUBLESHOOTING.md** – Signing, PLA, asset catalog, device run.
