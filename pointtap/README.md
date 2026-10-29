# PointTap

Simple sideline points tracker for training activities. Live at https://stldev.com/pointtap/

## Features

- **Players**: add names one at a time, or paste a comma or line separated list. Rename or remove players in edit mode.
- **Score**: big + and − buttons for each player. Points never drop below zero.
- **Undo**: undo the last tap (and keep undoing), plus undo for Reset Points, Remove Player and Clear Roster.
- **Reset Points**: sets everyone back to 0 and keeps the roster for the next activity.
- **Clear Roster**: removes all players and points.
- **Standings**: podium for the top three, full ranked list with ties sharing a rank.
- **Offline / Installable**: PWA with service worker; data is saved on the device with localStorage.

## Files

- `index.html` app
- `manifest.json`, `sw.js` PWA setup
- `icon.svg`, `icon-192.png`, `icon-512.png` icons
