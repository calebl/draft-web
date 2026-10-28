const CACHE_NAME = "draft-v2";
const OFFLINE_URL = "/offline.html";

const PRECACHE_URLS = [
  "/offline.html"
];

// Only static files are cached. App pages and other dynamic responses always go to
// the server: a stored page can replay an old redirect, such as New Session landing
// on an earlier session.
const STATIC_PATH_PREFIXES = ["/assets/", "/icons/", "/fonts/"];

const isStaticAsset = (request) => {
  const url = new URL(request.url);
  return request.method === "GET" &&
    url.origin === self.location.origin &&
    STATIC_PATH_PREFIXES.some((prefix) => url.pathname.startsWith(prefix));
};

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(PRECACHE_URLS))
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

self.addEventListener("fetch", (event) => {
  if (event.request.mode === "navigate") {
    event.respondWith(
      fetch(event.request).catch(() => caches.match(OFFLINE_URL))
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
