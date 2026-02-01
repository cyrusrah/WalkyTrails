# walkyTrails – Analysis & Plan to Publish on iOS

## 1. What I Analyzed

### TailTrails (similar project, abandoned)
- **Stack:** React Native, Expo (dev client), TypeScript, React Navigation, React Native Paper  
- **Backend:** Supabase (auth, database, storage), Mapbox, OpenWeatherMap  
- **Scope:** Full dog-walking app spec in `CONTEXT.md`: onboarding, auth, dog profiles, map, route planning, walk tracking, activity logging (pee/poop/water), shared routes, walk history, weather, POIs, community, gamification.  
- **Implementation:** Substantial but incomplete:
  - Auth, dog profiles, map with markers, shared routes, walk history, weather widget, navigation overlay, walk controls
  - MapScreen is 1,800+ lines; many features wired to Supabase/Mapbox
  - Route Details and Walk Tracking screens are “Coming Soon” placeholders
- **iOS:** Has native `ios/` folder, bundle ID `com.tailtrails.app`, location/camera permissions in Info.plist  
- **Why it stalled:** REMINDER.md shows dev-only overrides (e.g. location pinned to route start). Scope was large (8-phase roadmap, many tables), so “finish and ship” was hard.

### FlashRead (your published app)
- **Stack:** Native Swift/SwiftUI, Xcode project  
- **Scope:** Focused MVP: RSVP speed reading, text input, session save (UserDefaults), file import. No backend, no login.  
- **Store:** You followed a clear plan: App Store description, subtitle, keywords, privacy policy, screenshots, bundle ID `com.cyrus.FlashRead`, then build → archive → submit.  
- **Takeaway:** Small, well-defined scope and a repeatable publishing checklist made it shippable.

---

## 2. Lessons for walkyTrails

| From FlashRead | From TailTrails |
|----------------|-----------------|
| Ship a minimal, complete loop first | The product idea and UX (dog + walks + map) are solid |
| No backend for v1 if possible | Full spec in CONTEXT.md is a good long-term roadmap, not v1 |
| Clear App Store plan (assets, privacy, description) | Dev hacks (e.g. location override) must be removed before release |
| You already know: Xcode, bundle ID, entitlements, App Store Connect | Reuse patterns (navigation, contexts, services) if we use React Native |

---

## 3. Chosen direction: Swift (SwiftUI)

**Goal:** An app you can actually publish on iOS (like FlashRead), inspired by TailTrails but scoped so v1 is finishable.

**Decision: Swift.** You’ve already done the end-to-end flow with FlashRead (Xcode, archive, App Store Connect, review), so we’re reusing that path. No React Native / Expo; same toolchain and publishing playbook.

---

## 4. walkyTrails MVP (v1 – shippable)

Define v1 as the **smallest set of features that still feel like “walkyTrails”** and that you can ship.

**Core loop:**
1. **Start a walk** (one tap).
2. **During walk:** App tracks duration and distance (GPS). Optional: simple activity buttons (e.g. “Pee” / “Poop”) that log a timestamp (and maybe location) for later summary.
3. **End walk** → **Summary:** duration, distance, optional list of events. Option to “Save” so it appears in history.
4. **History:** List of past walks (date, duration, distance, optional notes). Local-only is enough for v1.

**Optional for v1 (keep or drop to hit ship date):**
- **One dog profile:** name, breed (and maybe photo) stored **locally** (e.g. UserDefaults / AsyncStorage). No accounts.
- **Map:** Either “no map” (just distance/duration) or a **single** static/simple map view showing the recorded path for the current or selected walk. No route planning, no POIs, no shared routes in v1.

**Explicitly out of v1:**
- No login, no Supabase, no backend.
- No route planning, no shared routes, no community, no weather, no gamification.
- No AI, no POIs.

This keeps scope close to FlashRead-level: one main flow, local data, clear value (“I can log my dog’s walks and see history”).

---

## 5. What we can do next (concrete steps)

### Phase 1 – Project setup (Swift, in this repo)
1. **Create the Xcode project**
   - In Xcode: **File → New → Project** → **iOS → App**.
   - Product Name: **walkyTrails** (or **WalkyTrails** if you prefer PascalCase for the target).
   - Team: your Apple Developer team.
   - Organization Identifier: e.g. **com.cyrus** (so Bundle ID = **com.cyrus.walkyTrails**).
   - Interface: **SwiftUI**. Language: **Swift**. No Core Data, no tests for now if you want to move fast.
   - Save the project **inside** `/Users/cyrusrahgoshay/Documents/Dev/walkyTrails/` (e.g. `walkyTrails/WalkyTrails.xcodeproj`).
2. **Naming and identity**
   - App name (display): **walkyTrails**
   - Bundle ID: **com.cyrus.walkyTrails**
   - Icon and launch screen: placeholder first; replace before App Store submission.

### Phase 2 – MVP features
1. **Walk recording**
   - Start / Stop with live duration (and distance if using location).
   - Store each walk: start time, end time, duration, distance, optional list of events (e.g. pee/poop with timestamp).
2. **Storage**
   - Local only: **UserDefaults** or **SwiftData** (Swift). One “walks” list and optionally one “current dog” object.
3. **Screens**
   - Home: big “Start Walk” and “Last walk” / “History” entry.
   - During walk: timer, distance, optional event buttons.
   - Summary: show stats and saved walk.
   - History: list of past walks.
4. **Permissions**
   - Location “when in use” (and “always” only if you need background distance). Copy TailTrails-style usage strings for App Store.

### Phase 3 – iOS publishing (same playbook as FlashRead)
1. **Privacy**
   - Privacy policy (hosted URL): what you collect (e.g. location only for distance, stored on device; no account, no server).
2. **App Store**
   - Name, subtitle, description, keywords, category (e.g. Lifestyle or Health & Fitness), age rating.
   - Screenshots (e.g. 6.7" iPhone), app icon, optional preview video.
3. **Build and submit**
   - **Swift:** Archive in Xcode → Distribute App → App Store Connect (same as FlashRead).
4. **Pre-submit**
   - Remove any dev-only behavior (no location spoofing, no debug menus in release).
   - Test on a real device and with a fresh install.

---

## 6. Reusing TailTrails without copying the scope

- **Use as reference:** CONTEXT.md (flow, future features), REMINDER.md (what to remove before ship), and TailTrails’ `src` structure (navigation, contexts, screens).
- **Do not copy:** Full schema, Mapbox/Supabase, route planning, shared routes, community, and multi-dog complexity into v1.
- **Later:** Once v1 is live, you can add e.g. one dog profile, then map, then optional backend (Supabase) for sync/accounts in v1.1+.

---

## 7. Summary

| Question | Answer |
|----------|--------|
| What did TailTrails give us? | Product vision, UX flow, and a lot of code we can use as reference—but v1 should be a small subset. |
| What did FlashRead give us? | Proof you can ship on iOS; reuse the same publishing process and “small MVP” mindset. |
| What should walkyTrails be for v1? | Start walk → track time/distance (and optional events) → end → summary → history. All local, no backend. |
| How do we get to “publish on iOS”? | 1) Build the MVP above. 2) Add privacy policy + App Store assets. 3) Archive in Xcode and submit to App Store Connect. 4) Fix review feedback if any, then release. |
| Tech choice | **Swift (SwiftUI)** – same end-to-end flow as FlashRead. |

**Next:** Create the Xcode project (Phase 1 above), then we can add the MVP screens and models (Walk, WalkStore, Home → During Walk → Summary → History).
