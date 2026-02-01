# WalkyTrails – Architecture

Short reference for where things live and how the app is structured. Helps humans and AI agents find the right place to change behavior.

## State and dependencies

- **Owned in app:** All stores and services are created in `WalkyTrailsApp` and injected once via `.environmentObject(...)`.
- **Stores:** `WalkStore`, `UserProfileStore`, `DogProfileStore`, `SettingsStore`.
- **Services:** `LocationManager`, `WeatherService`.
- **Views** use `@EnvironmentObject var store: WalkStore` (and same for others) instead of receiving them as parameters. No prop drilling.

## Flow and navigation

- **ContentView** is the root. It branches on app state:
  - `store.currentWalk != nil` → **DuringWalkView**
  - `store.walkToSummarize != nil` → **WalkSummaryView**
  - `!userStore.user.hasContent` → **UserProfileView** (onboarding)
  - `!dogStore.hasAnyDog` → **DogProfileView** (onboarding)
  - Else → **HomeView** inside a `NavigationStack`.
- **HomeView** → History → **WalkHistoryView** → **WalkDetailView**; Settings → **SettingsView**; profile → **UserProfileView**.
- **WalkDetailView** and **WalkHistoryView** get `store`, `settings`, `dogStore` from the environment; **WalkDetailView** also takes `walk: Walk` as a parameter.

## Formatting and display (single source of truth)

- **Walk display:** `Helpers/WalkDisplay.swift`
  - `formattedDuration(seconds:)` – "5 min 30 sec"
  - `formattedElapsed(from:now:)` – "12:34" (elapsed)
  - `dogsSummaryText(walk:dogStore:)` – "Rex, Luna" or "N dog(s) (no longer in profile)"
  - `eventLabel(event:dogStore:)` – dog name or "No longer in profile"
- **Event icon/color:** `Walk.swift` – `WalkEvent.EventType` has `iconName` and `displayColor`. Use these instead of duplicating switches in views.
- **Reusable UI:** `EventMarkerView` (map marker), `WalkMapView` (route + events map), `WeatherDisplayView` (weather row + suggestion).

## Persistence and export

- **WalkStore** owns: in-memory walks, current walk, walk-to-summarize; persistence (UserDefaults keys, load/save); export (ExportEnvelope, JSON/CSV, decode backup, replace walks). All in one type for now.
- **Export/restore:** Settings uses `store.exportAsJSONData(user:dogs:)`, `store.exportAsCSV()`, `WalkStore.decodeBackup(_)`, `store.replaceWalks(with:)`; user and dogs are applied via `userStore.update(_)` and `dogStore.replaceDogs(with:)`.

## Conventions (for edits)

- **New event type:** Add case to `WalkEvent.EventType` in `Walk.swift` and implement `iconName` and `displayColor` in the same enum.
- **New store or service:** Create it in `WalkyTrailsApp`, add `.environmentObject(...)` to the root view, then use `@EnvironmentObject` in views that need it.
- **Duration/dog/event display text:** Change only `Helpers/WalkDisplay.swift` and/or `WalkEvent.EventType` in `Walk.swift`.
- **Map or event marker look:** Change `WalkMapView` or `EventMarkerView` in `Views/`.
