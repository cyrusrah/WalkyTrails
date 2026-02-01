# WalkyTrails – Development Plan

**Vision:** Waze / Strava for dog walkers and owners — navigation, activity tracking, and (later) community, all centered on dog walks.

**Strategy:** Build **single-user** first (local, no backend). Add **community** and cloud later so the app stays shippable at every step.

---

## Docs that describe the concept

### WalkyTrails (this app)

| Doc | What it says |
|-----|----------------|
| **docs/CONTEXT.md** | WalkyTrails = iOS app for logging dog walks. Core: start walk → track duration + GPS distance + pee/poop events → end → summary → save to history. Local-only v1 (UserDefaults). Out of v1: login, map, route planning, community, weather, gamification, POIs, AI. Future: dog profile, map with path, later Supabase/Mapbox/community. |
| **docs/ANALYSIS_AND_PLAN.md** | Why Swift (FlashRead playbook). MVP = smallest "walkyTrails" loop: start → during (timer, distance, pee/poop) → summary → history. Optional v1: one dog profile, simple map (recorded path). Explicitly out of v1: login, route planning, shared routes, community, weather, gamification, AI, POIs. Phased steps (setup → MVP features). |
| **README.md** | Short product description: log dog walks, map, dog profile, history, local-only. How to run. |

### TailTrails (reference app)

| Doc | What it says |
|-----|----------------|
| **TailTrails/docs/CONTEXT.md** | Full technical spec: "Waze-like experience for dog owners." Target: millennial/Gen Z urban first-time dog owners. Route planning, activity tracking, community. Flow: onboarding → home (map, suggested routes, POIs) → route planning (AI, distance/energy/POIs) → during walk (turn-by-turn, pee/poop/water, weather) → post-walk → community (POIs, ratings, feed, leaderboards) → profile (user + dogs) → settings. DB: users, dogs, walks, activities, POIs, reviews, achievements, events, social. 8-phase roadmap (setup → auth → map → walk planning/tracking → weather/notifications → community → polish → launch). Future ideas: lost-dog alerts, health tracking, safety, gamification. |

**Takeaway:** WalkyTrails is the minimal, ship-first version of the same idea. TailTrails CONTEXT is the long-term product and feature reference; we phase those features into WalkyTrails (single-user first, then community).

---

## Current state (as of this plan)

**Done:**

- [x] Core loop: Start walk → during (timer, GPS distance, Pee/Poop/Water/Play with location) → end → summary → save/discard → history
- [x] Map: live path + event markers during walk; route + markers in walk detail (history)
- [x] One dog profile: name, breed, photo; onboarding, edit, delete; minimal row on Home
- [x] Splash + custom launch screen (logo on white)
- [x] Water / Play events (same flow as Pee/Poop; summary, detail, map)
- [x] Walk notes (optional per walk; editable in summary and walk detail)
- [x] Settings screen (units km/mi, date format, map style Standard/Hybrid/Satellite)
- [x] Basic stats on Home (walks this week, distance this week, streak)
- [x] Local-only (UserDefaults); no backend, no login
- [x] README, CONTEXT, MAP_STRATEGY, LAUNCH_SCREEN, App Store–related docs

**Not done yet:** Accessibility (VoiceOver, Dynamic Type, Reduce Motion), Export/backup. **Later phases:** Multi-dog, route planning, turn-by-turn, weather, backend, auth, community, POIs, gamification.

---

## Phased development plan

### Phase 1 – Single-user: polish and small wins  
*Goal: Better experience for one user, one dog, no backend.*

| # | Feature | Notes | Status |
|---|---------|--------|--------|
| 1.1 | Accessibility | VoiceOver labels for main actions (Start Walk, Pee, Poop, Water, Play, End Walk, Save, map). Dynamic Type, Reduce Motion. See docs/ACCESSIBILITY.md. | [x] |
| 1.2 | Water / Play events | Add Water and Play buttons during walk (same pattern as Pee/Poop, with location). | [x] |
| 1.3 | Walk notes | Optional text note per walk (e.g. "Sunny, park was busy"). | [x] |
| 1.4 | Export / backup | Export (JSON/CSV) and restore from JSON backup in Settings. See docs/EXPORT_RESTORE.md. | [x] |
| 1.5 | Settings screen | Units (km/mi), date format (short/medium/long), map style (Standard/Hybrid/Satellite). *Later:* about, privacy link. | [x] |
| 1.6 | Basic stats | Simple aggregates: total walks this week, distance this week, streak (on Home). | [x] |
| 1.7 | Siri hands-free | Log pee/poop/water/play via Siri during a walk (no touch). See docs/SIRI_PHRASES.md. | [x] |

**Phase 1 complete when:** All rows are [x] and validated. **Exit criteria:** App still local-only, one dog; better usability and a bit of "Strava-like" stats.

---

### Phase 1 – Steps and exit criteria (detail)

Use these to implement and to know when an item is done. Check off steps with `[x]` as you go.

#### 1.1 Accessibility
- **Steps:**
  - [x] Add VoiceOver labels to main actions (Start Walk, End Walk, event buttons, Save/Discard, navigation).
  - [x] Ensure key text and controls scale with Dynamic Type where reasonable.
  - [x] Where applicable, respect "Reduce Motion" (e.g. avoid unnecessary animations).
  - [ ] Run Accessibility Inspector / VoiceOver on main flows and fix issues.
- **Exit:** Main flows are usable with VoiceOver; labels are clear. Text doesn't break at larger type sizes; motion can be reduced.

#### 1.2 Water / Play events
- **Steps:**
  - [x] Add `water` and `play` to `WalkEvent.EventType` in `Walk.swift`.
  - [x] Add Water and Play buttons in `DuringWalkView` (same pattern as Pee/Poop).
  - [x] Add icons/colors for water and play in summary, detail, and map markers (e.g. cup, tennisball; cyan, orange).
  - [x] Ensure `WalkStore.addEventToCurrentWalk` and event list/map rendering handle all four types.
- **Exit:** User can log Water and Play during a walk; they appear in summary, history detail, and on the map with distinct icons/colors. No regressions for Pee/Poop.

#### 1.3 Walk notes
- **Steps:**
  - [x] Add optional `notes: String?` to `Walk` model; include in `init` and persistence.
  - [x] In `WalkStore`: add `setNotesForWalkToSummarize(_:)` and `updateNotes(for:notes:)` for saved walks.
  - [x] In `WalkSummaryView`: add notes text field; on change/Save, notes stored with the walk.
  - [x] In `WalkDetailView`: add Notes section with editable text field; persist on change.
- **Exit:** User can add/edit notes on summary and on saved walk detail. Notes persist after app restart.

#### 1.4 Export / backup
- **Steps:**
  - [x] Add "Export" (e.g. in Settings or History): serialize walks (and optionally dog profile) to JSON (or CSV).
  - [x] Use file exporter / share sheet or "Save to Files" so user can save to device or cloud.
  - [x] Add "Restore from backup": pick a previously exported JSON file, decode, confirm, then replace local walks and dog profile.
- **Exit:** User can export all walk history and dog profile to a JSON file and restore from that file (replace current data). See docs/EXPORT_RESTORE.md.

#### 1.5 Settings screen
- **Steps:**
  - [x] Add `SettingsStore` (UserDefaults): distance unit (km/mi), date format (short/medium/long), map style (standard/hybrid/imagery).
  - [x] Add `SettingsView` (Form + Pickers) and link from Home (e.g. gear in nav bar).
  - [x] Use settings for all distance formatting (during walk, summary, detail, Home stats).
  - [x] Use settings for date/time formatting in history and walk detail.
  - [x] Apply map style preference in `DuringWalkView` and `WalkDetailView`.
- **Exit:** Changing unit, date format, or map style in Settings updates all relevant screens; choices persist across launches.

#### 1.6 Basic stats
- **Steps:**
  - [x] Compute "walks this week" (count) and "distance this week" from `store.walks` using calendar week.
  - [x] Compute "streak": consecutive days (including today) with at least one walk.
  - [x] Add a small stats section on Home (card with these three numbers); show only when there is at least one saved walk.
  - [x] Use `SettingsStore.formattedDistanceShort` for distance so units match user preference.
- **Exit:** Home shows correct counts and streak; values update after new walks are saved; no crash with empty history.

---

### Phase 2 – Single-user: richer experience  
*Goal: Plan and analyze walks more like Strava; still no community.*

| # | Feature | Notes | Status |
|---|---------|--------|--------|
| 2.1 | Multi-dog | Multiple dog profiles; choose dog(s) per walk; history filtered by dog. | [ ] |
| 2.2 | Route planning (local) | "Plan a walk": set distance/duration or area; draw or pick waypoints; follow route during walk (no turn-by-turn yet). | [ ] |
| 2.3 | Turn-by-turn (optional) | Directions along a planned route (MapKit directions or similar). | [ ] |
| 2.4 | Weather | Current weather on during-walk and/or summary; optional "walk later" suggestion. | [ ] |
| 2.5 | Walk types | Tag walks: regular, training, social, vet visit (filter in history). | [ ] |
| 2.6 | Richer events | Optional: mood, short note, or photo per pee/poop/water/play. | [ ] |
| 2.7 | Stats and trends | Weekly/monthly distance, events over time, simple charts. | [ ] |

**Exit criteria:** Single-user app that feels "Strava-like" for dog walks (plan, record, review, stats), still local-first.

---

### Phase 3 – Backend and account (optional)  
*Goal: Sync and backup; optional login; no community yet.*

| # | Feature | Notes | Status |
|---|---------|--------|--------|
| 3.1 | Backend choice | Pick backend (e.g. Supabase, Firebase) for auth + sync. | [ ] |
| 3.2 | Auth | Sign up / sign in; optional "continue without account" (local-only). | [ ] |
| 3.3 | Sync | Walks and dog profiles sync across devices when logged in. | [ ] |
| 3.4 | Backup / restore | Cloud backup of history; restore on new device. | [ ] |

**Exit criteria:** Same single-user experience, with optional account and sync; still no shared/community content.

---

### Phase 4 – Community (Waze/Strava-like)  
*Goal: Shared routes, POIs, and social features.*

| # | Feature | Notes | Status |
|---|---------|--------|--------|
| 4.1 | Shared routes | Save a route and share (link or in-app); browse and use others' routes. | [ ] |
| 4.2 | POIs | User-generated POIs (water, waste, dog park, rest area); show on map; rate/review. | [ ] |
| 4.3 | Explore / feed | Feed of nearby or recent activity (e.g. "popular routes," "recent POIs"). | [ ] |
| 4.4 | Social | Optional: follow friends, see their walks (privacy controls), leaderboards. | [ ] |
| 4.5 | Gamification | Badges, streaks, challenges (e.g. weekly distance). | [ ] |

**Exit criteria:** App feels like "Waze/Strava for dog walkers": plan, record, share routes and POIs, light social layer.

---

## How to use this doc

- **Track:** Use the tables; mark items `[x]` when done. In Phase 1 detail, check off each step with `[x]` as you complete it.
- **Keep it current:** Update **Current state** and the phase tables as you ship so this doc stays the single source of truth.
- **Refer:** Before adding a feature, check which phase it belongs to; keep phases 1–2 free of community/backend scope.
- **Adjust:** Move items between phases or split them as you implement.
- **Vision:** Single-user first → optional backend/sync → then community (Waze/Strava for dog walkers).

---

## References

- **WalkyTrails:** `docs/CONTEXT.md`, `docs/ANALYSIS_AND_PLAN.md`, `README.md`
- **TailTrails (concept + features):** `TailTrails/docs/CONTEXT.md`
- **Map:** `docs/MAP_STRATEGY.md`
- **Launch / splash:** `docs/LAUNCH_SCREEN.md`
- **App Store:** `docs/APP_STORE_SUBMISSION.md`
