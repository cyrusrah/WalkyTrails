# WalkyTrails – App Icon

## AI image prompt (for DALL·E, Midjourney, etc.)

Use this prompt to generate an app icon, then crop/export as **1024×1024 PNG**:

```
App icon for "WalkyTrails", a dog walk logging app. Simple, flat design: a friendly dog silhouette or paw print combined with a trail/path or footsteps, on a soft rounded square background. Clean, modern, minimal style suitable for iOS. No text. Recognizable at small size. Warm, inviting colors (e.g. soft green for trails, earth tones, or blue sky). Square format, 1:1 aspect ratio.
```

**Shorter variant:**

```
iOS app icon, flat design: dog and walking trail or paw print with path, minimal, no text, warm colors, square, recognizable at small size.
```

---

## What’s set up

- **AppIcon.appiconset** is configured to use a single **1024×1024** image named **AppIcon.png**.
- Add that file to the app icon set and Xcode will use it for the app icon everywhere (home screen, App Store, etc.).

## Add your icon

1. **Create or export a 1024×1024 PNG**
   - No transparency for the App Store (use a solid background or rounded-rect).
   - Square canvas; iOS will apply the rounded mask.
   - Tools: Figma, Sketch, Canva, Preview (resize), or an icon generator.

2. **Name it exactly:** `AppIcon.png`

3. **Put it in the app icon set**
   - In Finder, go to:
     ```
     walkyTrails/WalkyTrails/WalkyTrails/Assets.xcassets/AppIcon.appiconset/
     ```
   - Drag **AppIcon.png** into that folder (same folder as **Contents.json**).

4. **In Xcode**
   - If the project is open: the new icon should appear in the asset catalog.
   - Clean build: **Product → Clean Build Folder** (⇧⌘K), then **Product → Build** (⌘B).
   - Run on simulator or device to confirm the home-screen icon.

## Quick placeholder (optional)

If you want a temporary icon:

- Use a 1024×1024 PNG with a single color and “WT” or a paw/trek icon.
- Or use [appicon.co](https://appicon.co) or similar: upload an image, download the generated set, and copy **AppIcon.png** (1024×1024) into **AppIcon.appiconset**.

## App Store

- The same 1024×1024 icon is used for the App Store listing.
- Apple recommends no transparency; a solid or rounded-rect design is fine.
