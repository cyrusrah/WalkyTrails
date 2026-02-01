# walkyTrails Privacy Page – Finish Setup

Repo: **https://github.com/cyrusrah/walkytrails-privacy**

Your privacy policy URL (after you finish): **https://cyrusrah.github.io/walkytrails-privacy/**

---

## Option A – Add the page from GitHub (no Terminal)

1. Go to **https://github.com/cyrusrah/walkytrails-privacy**
2. Click **“Add file”** → **“Create new file”**
3. In **“Name your file...”** type: **`index.html`**
4. Open **`walkyTrails/docs/privacy-page/index.html`** in your editor, select all (⌘A), copy (⌘C), then paste into the GitHub editor.
5. Click **“Commit new file”** → **“Commit changes”** (green button).
6. Go to **Settings** → **Pages** (left sidebar).
7. Under **“Build and deployment”** → **Source**: choose **“Deploy from a branch”**.
8. **Branch**: `main` — **Folder**: `/ (root)` — click **Save**.
9. Wait 1–2 minutes. Your URL: **https://cyrusrah.github.io/walkytrails-privacy/**

---

## Option B – Add the page from Terminal

1. On your Mac, open Terminal and run:

```bash
cd /Users/cyrusrahgoshay/Documents/Dev/walkyTrails/docs/privacy-page
git init
git add index.html
git commit -m "Add privacy policy page"
git branch -M main
git remote add origin https://github.com/cyrusrah/walkytrails-privacy.git
git push -u origin main
```

2. On GitHub: **https://github.com/cyrusrah/walkytrails-privacy** → **Settings** → **Pages**.
3. **Source**: “Deploy from a branch” → **Branch**: `main`, **Folder**: `/ (root)` → **Save**.
4. Wait 1–2 minutes. Your URL: **https://cyrusrah.github.io/walkytrails-privacy/**

---

## What to use in App Store Connect

**Privacy Policy URL:** `https://cyrusrah.github.io/walkytrails-privacy/`

Paste that in App Store Connect → your app → App Store tab → version → **Privacy Policy URL**.
