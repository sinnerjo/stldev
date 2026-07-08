const CACHE = 'subgo-v6';
const LOCAL_ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png'
];
const REMOTE_ASSETS = [
  'https://fonts.googleapis.com/css2?family=Barlow:wght@400;500;600&family=Barlow+Condensed:wght@600;700&family=DM+Mono&display=swap'
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(async c => {
      // Local assets must all succeed
      await c.addAll(LOCAL_ASSETS);
      // Remote assets are best-effort — a failure here won't block install
      await Promise.allSettled(
        REMOTE_ASSETS.map(url =>
          fetch(url, { mode: 'no-cors' })
            .then(res => c.put(url, res))
            .catch(() => {})
        )
      );
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// Network first — always try to get fresh files, fall back to cache when offline
self.addEventListener('fetch', e => {
  e.respondWith(
    fetch(e.request).catch(() => caches.match(e.request))
  );
});
