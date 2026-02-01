# Map strategy – WalkyTrails

## What map did TailTrails use?

**TailTrails (React Native)** used **Mapbox** via `@rnmapbox/maps`:

- **Mapbox MapView** with styles: outdoors, street, light, dark, satellite
- **ShapeSource + LineLayer** for the route polyline
- **PointAnnotation** for pee/poop (and drink/play) markers with icons at coordinates
- **MarkerView** for user/dog position
- **Mapbox Directions API** for route planning
- Access token in `src/services/mapbox/config.ts`

So TailTrails was “Mapbox + React Native.” WalkyTrails is **native Swift/SwiftUI**, so we choose a map stack for iOS only.

---

## What we need (Waze for dogs / AllTrails-style)

1. **During the walk**
   - Live map with **user position** and “follow me” behavior
   - **Path so far** drawn as a line (polyline)
   - **Pee/poop markers** on the map at the spot where the user tapped (using current GPS when they tap)

2. **After the walk**
   - Same **path** and **pee/poop markers** on the map in walk detail/history

3. **Data**
   - **Route:** array of coordinates (recorded as we get location updates)
   - **Events:** each pee/poop has a **location** (lat/lon) so we can place a marker

---

## Map choice for WalkyTrails (native iOS)

| Option | Pros | Cons |
|--------|------|------|
| **Apple MapKit** | Built-in, no API key, no cost, offline tiles, polyline + custom annotations, user tracking, App Store / privacy friendly | Styling is standard/satellite/hybrid only (no “outdoors” theme) |
| **Mapbox (native iOS)** | Outdoors style like TailTrails, custom styles, you already have a token | Extra SDK, token in app, setup (SPM/CocoaPods) |
| **Google Maps** | Familiar look, good APIs | API key, quota, another vendor |

---

## Recommendation: **MapKit first**

- **Fits the product:** path line, pee/poop markers, follow-me – all supported (MapPolyline, MapAnnotation, user location).
- **Simplest:** no keys, no SDK, works with cached tiles offline.
- **Same data model either way:** we store **route coordinates** and **event coordinates**; if you add Mapbox later for “outdoors” style, we keep the same data and only swap the map view.

**If you want the TailTrails “outdoors” look later:** we can add the Mapbox iOS SDK and a map style, and keep using the same route + event coordinates.

---

## Implementation plan (MapKit)

1. **Data**
   - **Walk:** add `routeCoordinates: [CLLocationCoordinate2D]` (or `[[lat, lon]]` encoded).
   - **WalkEvent:** add optional `latitude` / `longitude` (or a small `Codable` coordinate type) so each pee/poop has a location.
   - **LocationManager:** expose **current location** and append to a **path** (or expose locations and let WalkStore build the path).

2. **During walk**
   - **DuringWalkView:** add a **Map** (SwiftUI) showing:
     - User location (default MapKit behavior)
     - **MapPolyline** for `routeCoordinates` so far
     - **MapAnnotation** for each event (pee/poop) with a small icon at the event’s coordinate
   - When user taps Pee/Poop, record **current location** into the new event.
   - Optionally: “follow me” camera (center on user, or use `MapCameraPosition.follow`-style APIs where available).

3. **After walk**
   - **WalkDetailView:** same map: polyline for full route + annotations for each event.

4. **Persistence**
   - Encode `routeCoordinates` and event lat/lon in the existing `Walk` / `WalkEvent` Codable model (e.g. arrays of `[Double]` or a wrapper type) so saved walks have path + markers for history.

---

## Summary

- **TailTrails:** Mapbox (`@rnmapbox/maps`) for map, route line, and markers.
- **WalkyTrails:** Use **MapKit** for the first version: path + pee/poop markers + tracking, no keys, same data model. Add Mapbox later only if you want the outdoors style.

Next step: implement the data changes (route + event coordinates) and then the MapKit UI (during-walk map + walk-detail map).

---

## Visualizing walks in history

**Yes.** Every saved walk can be visualized on a map in history.

**How it works**

- Each saved **Walk** will store:
  - **Route:** full path (array of coordinates) from start to end.
  - **Events:** each pee/poop with its **location** (lat/lon) at the time of tap.
- **History** → tap a walk → **Walk Detail** screen shows:
  - **Map at the top:** full route as a line + pee/poop markers at their locations.
  - **Below:** same summary you have now (duration, distance, date/time) and the events list (with time); the map gives the “where” for the whole walk and for each event.

**Older walks (before we add the map)**  
Walks saved without route/event coordinates will have an empty path and no event locations. We can:
- Show the map only when the walk has at least one route point (or hide the map section when empty), and
- Still show the events list (time only) for those older walks.

So: **all new walks** will be visualizable on the map in history; **old walks** keep list-only until you optionally backfill or ignore.

---

## User journey we can accommodate

| Step | Screen | Map / journey |
|------|--------|----------------|
| **1** | Home | No map. Start Walk, History, Dog profile. |
| **2** | **During walk** | **Map** (live): your position, path so far, pee/poop markers as you tap. Duration, distance, Pee/Poop buttons, End Walk. “Follow me” so the map stays centered on you (optional). |
| **3** | **Summary** | No map. Duration, distance, event count. Save or Discard. |
| **4** | **History** | List of past walks (date, duration, event count). Tap a walk → Walk Detail. |
| **5** | **Walk detail** | **Map** (static): full route + pee/poop markers. Below: duration, distance, date/time, events list. Replay of “where” you walked and where each event happened. |

**Flows we support**

- **Live walk:** Home → Start Walk → see map + path + add pee/poop on the map → End Walk → Summary → Save.
- **Review past walk:** Home → History → tap walk → see map of that walk + stats + events (visualize walks in history).
- **Quick log (no map):** If we ever skip recording the path (e.g. low battery mode), we still save duration/events; history shows list-only for that walk or a “no route” state on the map.

**Summary:** You get a **during-walk** map (path + markers as you go) and a **history** map per walk (same path + markers) so you can visualize every walk in history the same way.
