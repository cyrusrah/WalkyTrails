# WalkyTrails – Build troubleshooting

## 1. "PLA Update available" / "No profiles for 'com.cyrus.WalkyTrails' were found"

**Cause:** Apple’s Program License Agreement (PLA) hasn’t been accepted, so Xcode can’t create or use provisioning profiles.

**Fix:**

1. **Accept the latest agreement**
   - In a browser, go to **[developer.apple.com](https://developer.apple.com)** and sign in with the same Apple ID you use in Xcode.
   - If a banner or prompt appears about a new **Program License Agreement** or **Apple Developer Program License Agreement**, open it and **Agree**.
   - If you don’t see a prompt: go to **Account** (top right) → **Membership** (or **Agreements, Tax, and Banking**) and check for any agreement that says **Action Required** or **Review**; open and accept it.

2. **Try again in Xcode**
   - Wait a minute after accepting, then in Xcode go to **Signing & Capabilities** for the WalkyTrails target and click **Try Again**, or run the app again (⌘R).
   - Xcode should then be able to create an **Xcode Managed Profile** for `com.cyrus.WalkyTrails` and the “No profiles” error should go away.

3. **If “No profiles” persists**
   - In Xcode: **Signing & Capabilities** → ensure **Team** is set to your Apple ID.
   - Turn **Automatically manage signing** off, then on again.
   - Run the app again so Xcode can regenerate the profile.

---

## 2. See the actual error

- In Xcode, after a failed build: **View → Navigators → Report** (or **⌘9**).
- Click the **last failed build** and read the **red error lines** at the top.
- Copy the **exact** error text (e.g. "Signing for WalkyTrails requires...", "Cannot find type 'Walk'...") so you can fix or search it.

---

## 3. "Signing for WalkyTrails requires a development team"

- Click the **WalkyTrails** project (blue icon) in the left sidebar.
- Select the **WalkyTrails** target (under TARGETS).
- Open the **Signing & Capabilities** tab.
- Under **Team**, choose your **Apple ID** (or **Add an Account…** and sign in).
- Leave **Automatically manage signing** checked.

---

## 4. "Cannot find type 'Walk' in scope" / missing types

The app target might not be compiling all source files (e.g. in `Models/` or `Views/`).

- In the project navigator, confirm you see **WalkyTrails** (the app folder) and inside it: **Models**, **Views**, **WalkStore.swift**, **ContentView.swift**, **WalkyTrailsApp.swift**.
- If **Models** or **Views** are missing or grayed out: **File → Add Files to "WalkyTrails"** → select the **Models** and **Views** folders → check **Copy items if needed** and **Add to targets: WalkyTrails** → Add.

---

## 5. Clean and rebuild

- **Product → Clean Build Folder** (⇧⌘K).
- Then **Product → Build** (⌘B).

---

## 6. Running on your iPhone

- Set **Team** in Signing & Capabilities (see §2).
- Connect the iPhone, choose it as the run destination, then **Run** (▶).
- If iOS says **Untrusted Developer**: on the phone go to **Settings → General → VPN & Device Management** → tap your Apple ID → **Trust**.

If it still fails, paste the **exact error message** from the Report navigator so we can target the fix.
