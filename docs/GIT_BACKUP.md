# WalkyTrails – Back up to Git

Your project has a `.gitignore` but no Git repo yet. Use these steps to back up the code and (optionally) push to GitHub.

---

## 1. Create a Git repo locally

In **Terminal**, from the walkyTrails folder:

```bash
cd /Users/cyrusrahgoshay/Documents/Dev/walkyTrails
git init
git add .
git status
git commit -m "Initial commit: WalkyTrails app, docs, and submission guide"
```

You now have a local repo; your code is versioned.

---

## 2. (Optional) Push to GitHub

**A. Create a new repo on GitHub**

- Go to **[github.com/new](https://github.com/new)**.
- **Repository name:** `walkyTrails` (or `WalkyTrails`).
- **Public**, no README, no .gitignore (you already have one).
- Click **Create repository**.

**B. Add remote and push**

In Terminal (same folder):

```bash
git remote add origin https://github.com/YOUR_USERNAME/walkyTrails.git
git branch -M main
git push -u origin main
```

Replace **YOUR_USERNAME** with your GitHub username (e.g. `cyrusrah`).

---

## 3. Later: save more changes

Whenever you change code or docs:

```bash
cd /Users/cyrusrahgoshay/Documents/Dev/walkyTrails
git add .
git status
git commit -m "Short description of what you changed"
git push
```

---

**Summary:** Run the commands in **§1** to back up locally. Run **§2** if you want a copy on GitHub too.
