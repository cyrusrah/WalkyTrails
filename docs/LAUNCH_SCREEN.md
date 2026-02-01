# Launch experience

## What you have

1. **System Launch Screen** – Shown by iOS as soon as the user taps the app icon (before any Swift runs). The project uses a **custom** launch screen via **Info.plist** (`UILaunchScreen`): **SplashLogo** image centered on **LaunchScreenBackground** (white), so the first frame matches the in‑app splash.

2. **In‑app splash** – **SplashView** (logo + “WalkyTrails” + tagline) is shown for **1.5 seconds** after the app loads, then the app transitions to onboarding or Home. Same logo and feel as the system launch screen.

**Files:** `WalkyTrails/Info.plist` (UILaunchScreen), `Assets.xcassets/LaunchScreenBackground.colorset`, `Assets.xcassets/SplashLogo.imageset`, `Views/SplashView.swift`.

## Do you need both?

Yes. The **Launch Screen** is shown by the system before your app runs (no code). The **Splash** is shown by your app for a short branded moment after load. Together they give one continuous brand moment: tap icon → Launch Screen (logo on white) → Splash (same logo + text) → Home/onboarding.

## Tweaks

- **Splash duration** – In **WalkyTrailsApp.swift**, change `1.5` in `DispatchQueue.main.asyncAfter(deadline: .now() + 1.5)` (e.g. 1.0 or 2.0 seconds).
- **Launch Screen background** – Edit **LaunchScreenBackground.colorset** (e.g. light gray to match system background).
- **Splash design** – Edit **Views/SplashView.swift** (text, layout).
