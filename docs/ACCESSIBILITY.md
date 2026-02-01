# WalkyTrails – Accessibility

## Implemented

### VoiceOver
- **Home:** Start Walk, History, Dog profile, Settings (gear). Stats section has a combined label (walks this week, distance, streak).
- **During walk:** Map (route + event markers), elapsed time, distance, Log Pee/Poop/Water/Play (with hints), End Walk.
- **Summary:** Walk summary header, notes field, Discard, Save.
- **Walk detail:** Map, summary section, notes field (saved automatically). Events list uses default list behavior.
- **History:** Each row has a combined label (date, duration, event count) and hint “Opens walk details.”
- **Settings:** Pickers use their titles (Distance unit, Temperature, Date format, Map style); Form sections are standard.
- **Dog profile:** Change photo, Remove photo, Dog’s name, Save, Delete profile (with hints).

### Dynamic Type
- Text uses semantic fonts (`.title`, `.headline`, `.body`, `.caption`, etc.) so it scales with the user’s text size.
- Timer and stats use `.title2` / `.largeTitle` and scale.
- Icon-only elements (toolbar paw, gear, map markers) use fixed sizes so layout stays stable; they have `accessibilityLabel`/`accessibilityHint` so VoiceOver describes them.

### Reduce Motion
- No custom animations; navigation and transitions use system behavior, which respects **Settings → Accessibility → Motion → Reduce Motion**.

## Testing with Accessibility Inspector

1. In Xcode: **Product → Profile** (or run on device/simulator), then **Xcode → Open Developer Tool → Accessibility Inspector**.
2. Select the WalkyTrails process (or simulator).
3. Use **Inspection** to select elements and check:
   - Label and hint for buttons and links.
   - Combined labels for groups (e.g. stats, map).
4. Use **Audit** to run automatic checks (labels, contrast, touch targets, etc.).
5. Test with **VoiceOver** (Settings → Accessibility → VoiceOver) and different **Display → Text Size** and **Motion** settings.

## Optional improvements (future)

- Add `accessibilityActions` on the map for “Log event here” if we add tap-to-log.
- Revisit icon sizes with `@ScaledMetric` if we want them to scale with Dynamic Type.
- Run a full contrast audit and adjust colors if needed.
