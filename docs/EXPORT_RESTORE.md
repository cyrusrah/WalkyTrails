# WalkyTrails – Export and Restore

## Overview

- **Export:** Back up walk history and dog profile to a file (JSON) or spreadsheet (CSV).
- **Restore:** Replace current data with a previously exported JSON backup.

All in **Settings → Export**.

---

## Export

### Export as JSON (full backup)

- **Contains:** Walk history + dog profile (name, breed, photo) if set.
- **Format:** JSON with `version`, `exportedAt`, `dog` (optional), `walks`. Dates are ISO8601.
- **Use:** Full backup; use this file for **Restore from backup**.
- **Flow:** Tap **Export as JSON** → share sheet opens → save to Files, AirDrop, Messages, etc.

### Export as CSV (walks only)

- **Contains:** One row per walk: Start, End, Duration (sec), Distance (m), Notes, Events.
- **Use:** Spreadsheets, analysis; not used for restore.
- **Flow:** Tap **Export as CSV** → share sheet opens → save or share.

---

## Restore from backup

### User journey

1. **Settings → Export** → tap **Restore from backup**.
2. **Pick file:** Document picker opens; choose a previously exported **JSON** file (e.g. from Files, iCloud, or another device).
3. **Confirm:** Alert shows what will be restored (e.g. “X walk(s), dog profile (Name)”). **Replace** overwrites current walks and dog profile; **Cancel** does nothing.
4. **Done:** “Restore complete” alert. Current walk history and dog profile are now the backup’s data.

### Behavior

- **Replace only:** Restore overwrites all current walks and the dog profile. There is no merge.
- **Valid file:** Must be a WalkyTrails JSON backup (same format as **Export as JSON**). Invalid or other files show “This file is not a valid WalkyTrails backup.”
- **Empty backup:** Restore is allowed; it clears walks and resets dog profile.

### Technical

- Decoding uses `WalkStore.decodeBackup(_:)` (ISO8601 dates).
- Apply: `store.replaceWalks(with: envelope.walks)` and, if present, `dogStore.save(envelope.dog)`.
