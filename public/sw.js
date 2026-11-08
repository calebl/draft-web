const CACHE_NAME = "draft-v3";
const OFFLINE_URL = "/offline.html";
// The writing page Draft opens when it cannot reach home. It holds no stories or sessions.
const OFFLINE_WRITE_URL = "/offline-write";

// Only static files are cached. App pages and other dynamic responses always go to
// the server: a stored page can replay an old redirect, such as New Session landing
// on an earlier session. The offline writing page is the one exception: it is static,
// and it is only ever shown when a page fails to load.
const STATIC_PATH_PREFIXES = ["/assets/", "/icons/", "/fonts/"];

const isStaticAsset = (request) => {
  const url = new URL(request.url);
  return request.method === "GET" &&
    url.origin === self.location.origin &&
    STATIC_PATH_PREFIXES.some((prefix) => url.pathname.startsWith(prefix));
};

const isStaticPath = (path) => STATIC_PATH_PREFIXES.some((prefix) => path.startsWith(prefix));

// Same-origin static files a page or stylesheet refers to: its scripts, the modules in
// its import map, its stylesheets and the fonts they load.
const staticPathsIn = (text) => {
  const paths = new Set();
  for (const match of text.matchAll(/["'(]((?:\/[\w.@-]+)+\.(?:js|css|ttf|woff2?|png|svg))["')]/g)) {
    if (isStaticPath(match[1])) paths.add(match[1]);
  }
  return [...paths];
};

// Stores the offline writing page with everything it needs to run. Asset names change
// when Draft is updated, so this runs again after pages load.
const cacheOfflineWritePage = async () => {
  const cache = await caches.open(CACHE_NAME);
  const response = await fetch(OFFLINE_WRITE_URL, { cache: "no-store" });
  if (!response.ok) return;

  const html = await response.clone().text();
  const assets = staticPathsIn(html);
  const fonts = [];
  await Promise.all(assets.map(async (path) => {
    if (await cache.match(path)) return;
    const asset = await fetch(path);
    if (!asset.ok) throw new Error(`Could not store ${path}`);
    if (path.endsWith(".css")) fonts.push(...staticPathsIn(await asset.clone().text()));
    await cache.put(path, asset);
  }));
  await Promise.all(fonts.map(async (path) => {
    if (!(await cache.match(path))) await cache.add(path);
  }));
  // The page is stored last, so it is never there without its scripts and styles.
  await cache.put(OFFLINE_WRITE_URL, response);
};

let lastRefresh = 0;
const REFRESH_INTERVAL_MS = 10 * 60 * 1000;

const refreshOfflineWritePage = () => {
  if (Date.now() - lastRefresh < REFRESH_INTERVAL_MS) return Promise.resolve();
  lastRefresh = Date.now();
  return cacheOfflineWritePage().catch(() => { lastRefresh = 0; });
};

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll([OFFLINE_URL]))
      .then(() => refreshOfflineWritePage())
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key)))
    )
  );
  self.clients.claim();
});

const offlinePage = async () =>
  (await caches.match(OFFLINE_WRITE_URL)) || caches.match(OFFLINE_URL);

self.addEventListener("fetch", (event) => {
  if (event.request.mode === "navigate") {
    event.respondWith(
      fetch(event.request).then((response) => {
        // Keep the stored offline page current; the page itself is never stored.
        event.waitUntil(refreshOfflineWritePage());
        return response;
      }, offlinePage)
    );
    return;
  }

  if (!isStaticAsset(event.request)) return;

  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) return cached;
      return fetch(event.request).then((response) => {
        if (!response || response.status !== 200 || response.type !== "basic") {
          return response;
        }
        const toCache = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, toCache));
        return response;
      });
    })
  );
});
