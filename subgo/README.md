# ⚽ Soccer Tracker

A mobile-friendly web app for tracking soccer player positions, substitutions, and minutes during games.

## Features

- **Roster** — Add players with jersey number and name
- **Game** — Visual soccer field with drag-and-drop player placement across 13 position slots
- **Pending Subs** — Queue substitutions in advance, call them out loud with one tap, then confirm all at once when play stops
- **Sub Shoutout** — Full-screen display showing who's coming off and who's coming on by number and name
- **Summary** — Per-game minutes table per player with CSV export
- **Offline** — Works without internet after first load (PWA)
- **Installable** — Add to home screen on Android or iOS for a full-screen app experience

## Deploy to GitHub Pages

1. Go to [github.com](https://github.com) and create a free account if you don't have one
2. Click **New repository**, name it `soccer-tracker`, set to **Public**, click **Create repository**
3. Click **Add file → Upload files** and upload all files in this folder:
   - `index.html`
   - `manifest.json`
   - `sw.js`
   - `icon-192.png`
   - `icon-512.png`
4. Click **Commit changes**
5. Go to **Settings → Pages**
6. Under **Source** select **Deploy from a branch**, choose `main` and `/ (root)`, click **Save**
7. Wait about 60 seconds — your app is live at `https://YOUR-USERNAME.github.io/soccer-tracker`

## Install on Android

1. Open the app URL in Chrome on your Android phone
2. Tap the three-dot menu → **Add to Home screen**
3. Tap **Add** — the app appears on your home screen and opens full-screen

## Install on iPhone

1. Open the app URL in Safari
2. Tap the Share button → **Add to Home Screen**
3. Tap **Add**

## Updating

To update the app after making changes, just re-upload `index.html` to your GitHub repo. GitHub Pages deploys automatically within about a minute.
