// New Session and Write start a session with a POST sent by Turbo. When home is out of reach
// that request fails without loading a page, so the service worker never gets to show the
// offline writing page. Open it ourselves, with the story already picked, so the writer can
// start writing straight away; the session is created when home is reachable again.

const NEW_SESSION_PATH = /^\/stories\/(\d+)\/writing_sessions\/?$/;

document.addEventListener("turbo:fetch-request-error", (event) => {
    const {request} = event.detail;
    if (String(request.method).toUpperCase() !== "POST") return;

    const match = new URL(request.url, window.location.href).pathname.match(NEW_SESSION_PATH);
    if (!match) return;

    event.preventDefault();
    window.location.assign(`/offline-write?story=${match[1]}`);
});
