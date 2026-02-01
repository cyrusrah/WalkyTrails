# walkyTrails – App Store Submission Guide

Use this doc end-to-end: copy text where indicated, do steps in order.

---

## 1. Privacy policy (required)

### 1.1 Text to use

Copy this entire block. You will host it at a **public URL** (see 1.2).

```
Privacy Policy for WalkyTrails

Effective Date: [Today's date, e.g. January 31, 2026]

WalkyTrails does not collect, store, or share any personal information. All data stays on your device.

• Walk logs (start/end time, duration, events) are stored only on your iPhone or iPad.
• No account is required. No data is sent to any server.
• We do not use analytics, advertising, or third-party tracking.

If you have questions, contact the developer through the App Store listing.
```

### 1.2 Where to host it (same idea as FlashRead)

**Option A – GitHub Pages (recommended, like FlashRead)**

A ready-to-use page is in your repo: **`docs/privacy-page/index.html`**. Use it to get a URL:

1. **Create a new repo on GitHub** named `walkytrails-privacy` (or `walkyTrails-privacy`). Don’t add a README.
2. **On your Mac:** Create a folder, put **only** `index.html` in it (copy from `walkyTrails/docs/privacy-page/index.html`).
3. **Terminal** in that folder:
   ```bash
   git init
   git add index.html
   git commit -m "Privacy policy"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/walkytrails-privacy.git
   git push -u origin main
   ```
   (Replace `YOUR_USERNAME` with your GitHub username.)
4. **On GitHub:** Repo → **Settings** → **Pages** → under “Build and deployment”, **Source** = “Deploy from a branch” → **Branch** = `main`, folder = `/ (root)` → **Save**.
5. **Wait 1–2 minutes.** Your URL will be:  
   **`https://YOUR_USERNAME.github.io/walkytrails-privacy/`**  
   (Replace `YOUR_USERNAME` with your GitHub username.)

**Option B – Notion**

Create a new page, paste the text from 1.1, then **Share** → **Publish to web** → copy the link.

**Option C – Your own site**

Create a page (e.g. `/privacy` or `/walkytrails-privacy`) and paste the text from 1.1.

**Save your privacy policy URL** — you will paste it in App Store Connect (step 4).

---

## 2. App Store listing text

### 2.1 Name (30 characters max)

```
WalkyTrails
```
or
```
WalkyTrails – Dog Walk Logger
```

### 2.2 Subtitle (30 characters max)

```
Log your dog walks.
```

### 2.3 Description (copy this)

```
Log your dog walks in one tap.

WalkyTrails lets you start a walk, track duration, log quick events (pee/poop), and save a summary to your history. All data stays on your device—no account, no server.

• Start / stop a walk with one tap
• Live timer during the walk
• Optional event buttons (Pee, Poop) with timestamps
• Post-walk summary: duration and events
• History list: tap any walk to see full details
• No login, no tracking—everything stays on your phone

Perfect for keeping a simple log of your dog’s walks. Data is stored locally only.
```

### 2.4 Keywords (100 characters max, comma‑separated, no spaces after commas)

```
dog walk,walk logger,pet,dog,walks,log,trails,dog walking
```

### 2.5 Category

- **Primary:** Lifestyle (or Health & Fitness)
- **Secondary:** (optional) Health & Fitness or Productivity

### 2.6 Age rating

- **4+** (no objectionable content)

---

## 3. Screenshots – what to capture and where to add them

### 3.1 What to capture

Use **iPhone 15 Pro Max** or **iPhone 14 Pro Max** simulator (6.7" display), or a real device with that size. Capture **at least 3, up to 10** screens in this order:

1. **Home** – “Start Walk” and “History” visible.
2. **During walk** – Timer running, Pee/Poop buttons, “End Walk” visible.
3. **Summary** – After ending a walk: duration, events (if any), Save/Discard.
4. **History** – List of saved walks (do a couple of test walks first if needed).
5. **Walk detail** – One walk opened from History (duration, events list).

### 3.2 Required screenshot dimensions (6.7" iPhone)

App Store Connect accepts **only** these sizes for 6.7" iPhone:

- **Portrait:** **1284 × 2778** px (or 1242 × 2688 px)
- **Landscape:** **2778 × 1284** px (or 2688 × 1242 px)

If your simulator screenshots are the wrong size, resize them (see 3.3).

### 3.3 How to capture (Simulator)

1. In Xcode: run on **iPhone 15 Pro Max** (or 14 Pro Max) simulator.
2. Navigate to each screen above.
3. **⌘S** in Simulator saves a screenshot to Desktop (or **File → Save Screen**).
4. Name them clearly, e.g. `01-home.png`, `02-during-walk.png`, etc.
5. If upload fails with “dimensions are wrong”, resize to **1284 × 2778** (see below).

### 3.4 Resize screenshots to 1284 × 2778 (Mac)

**Option A – Preview**

1. Open the screenshot in **Preview**.
2. **Tools** → **Adjust Size…**
3. Uncheck “Scale proportionally” (or adjust so width and height match below).
4. **Width:** 1284 — **Height:** 2778 (portrait).
5. **OK** → **File** → **Save** (or Export as PNG).

**Option B – Terminal (sips)**

From the folder that contains your screenshots (e.g. Desktop):

```bash
# Resize one file (portrait 1284 × 2778)
sips -z 2778 1284 01-home.png

# Resize all PNGs in the current folder
for f in *.png; do sips -z 2778 1284 "$f"; done
```

(`sips -z` is height then width: 2778 height, 1284 width = portrait.)

### 3.5 Where to add them

- In **App Store Connect** → your app → **App Store** tab → under **Screenshots**, select **6.7" iPhone** and upload images that are **1284 × 2778** (or one of the other accepted sizes). See step 4 below.

---

## 4. App Store Connect – where to do what

### 4.1 Open App Store Connect

- Go to **[appstoreconnect.apple.com](https://appstoreconnect.apple.com)** and sign in with your Apple Developer account.

### 4.2 Create the app (if not already)

1. **My Apps** → **+** → **New App**.
2. **Platforms:** iOS.
3. **Name:** WalkyTrails (or the name you chose in 2.1).
4. **Primary Language:** English.
5. **Bundle ID:** Select **com.cyrus.WalkyTrails** (must match Xcode; create it in Developer portal if needed).
6. **SKU:** e.g. `walkytrails2026` (any unique string).
7. **User Access:** Full Access.
8. Create.

### 4.3 Fill the listing (App Store tab)

1. Open your app → **App Store** tab.
2. Under **App Information** / **Version Information** for the new version (e.g. 1.0):
   - **Name:** (from 2.1)
   - **Subtitle:** (from 2.2)
   - **Description:** (from 2.3)
   - **Keywords:** (from 2.4)
   - **Support URL:** (your email or a simple support page; can be same as privacy or “mailto:you@example.com”)
   - **Marketing URL:** (optional)
   - **Privacy Policy URL:** **Paste the URL from step 1.2 here.** (Required.)
3. **Screenshots:** Under 6.7" iPhone, upload the screenshots from step 3.
4. **App Icon:** Already in your build; no need to upload again here if you used a 1024×1024 in the asset catalog.
5. **Age Rating:** Answer the questionnaire (all “None” / no harmful content) → 4+.
6. **Category:** (from 2.5)

### 4.4 Build (upload from Xcode first – see step 5)

- In the same version (1.0), under **Build**, click **+** and select the build you uploaded. If you haven’t uploaded yet, do step 5 first, then come back and select the build.

### 4.5 Submit for Review

- Add **What’s New in This Version** (e.g. “Initial release. Log your dog walks with duration and events; all data stays on device.”).
- **Export Compliance:** Typically “No” (no encryption beyond standard iOS).
- **Advertising Identifier:** No (if you don’t use ads).
- **Content Rights / Third-Party Content:** Confirm you have rights; if it’s all yours, no extra steps.
- Click **Submit for Review**.

---

## 5. Xcode – archive and upload

### 5.1 Where: Xcode

1. Open **WalkyTrails** in Xcode.
2. Select run destination: **Any iOS Device** (not a simulator).
3. **Product → Archive**.
4. When the **Organizer** opens, select the new archive → **Distribute App**.
5. **App Store Connect** → Next.
6. **Upload** → Next.
7. Options: leave defaults (e.g. upload symbols, manage version/build) → Next.
8. **Automatically manage signing** if prompted → Next.
9. **Upload**. Wait until the upload finishes.

### 5.2 Where: App Store Connect (again)

1. Go back to **[appstoreconnect.apple.com](https://appstoreconnect.apple.com)** → your app → **App Store** tab.
2. The new build can take **5–15 minutes** to appear. Refresh until you see it.
3. Under **Build**, click **+** and select that build.
4. Complete any remaining fields and **Submit for Review** (see 4.5).

---

## 6. Checklist before you submit

- [ ] Privacy policy hosted at a public URL; URL pasted in App Store Connect.
- [ ] Name, subtitle, description, keywords, category, age rating filled in.
- [ ] 6.7" iPhone screenshots uploaded (at least 3).
- [ ] Build uploaded from Xcode and selected in the version.
- [ ] “What’s New” and export compliance / advertising questions answered.
- [ ] **Submit for Review** clicked.

---

## 7. After submission

- **Review:** Usually 1–3 days. Check **App Store Connect → My Apps → [your app] → App Store** for status.
- **If rejected:** Read the resolution center message, fix the issue, then resubmit (new build or same build, depending on what they ask).
- **If approved:** In the version page, choose **Release** (manual or automatic). The app will go live on the App Store.

---

**Quick reference – where what lives**

| What              | Where |
|-------------------|--------|
| Privacy policy    | Host on GitHub Pages / Notion / your site → paste URL in App Store Connect |
| Name, subtitle, description, keywords | App Store Connect → your app → App Store tab → version |
| Screenshots       | App Store Connect → same version → Screenshots → 6.7" iPhone |
| Build             | Xcode: Product → Archive → Distribute → Upload → then select in App Store Connect |
| Submit            | App Store Connect → version → Submit for Review |
