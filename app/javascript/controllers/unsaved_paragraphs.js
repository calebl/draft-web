// Paragraphs stay on the phone until home confirms them saved. Each one is kept in
// localStorage under its session with an id of its own, and sent one at a time, in order.
// A paragraph whose reply was lost is sent again; the server knows its id and skips it.
// Sending resumes when the connection returns, when Draft comes back to the screen, when a
// page loads, and on a slow timer.

const KEY_PREFIX = "draft.unsaved.";
const RETRY_INTERVAL_MS = 30000;
export const CHANGED_EVENT = "draft:unsaved-changed";
export const MOVED_EVENT = "draft:unsaved-moved";

let sending = false;
const memoryQueues = new Map();

const keyFor = (sessionId) => `${KEY_PREFIX}${sessionId}`;

const read = (sessionId) => {
    const id = String(sessionId);
    if (memoryQueues.has(id)) return memoryQueues.get(id);

    try {
        return JSON.parse(localStorage.getItem(keyFor(id))) || [];
    } catch {
        return [];
    }
};

const write = (sessionId, paragraphs, memoryOnly = memoryQueues.has(String(sessionId))) => {
    const id = String(sessionId);
    if (memoryOnly) {
        if (paragraphs.length) memoryQueues.set(id, paragraphs);
        else memoryQueues.delete(id);
        return;
    }

    try {
        if (paragraphs.length) {
            localStorage.setItem(keyFor(id), JSON.stringify(paragraphs));
        } else {
            localStorage.removeItem(keyFor(id));
        }
    } catch {
        if (paragraphs.length) memoryQueues.set(id, paragraphs);
    }
};

const sessionIds = () => {
    const ids = new Set([...memoryQueues.entries()]
        .filter(([, paragraphs]) => paragraphs.length)
        .map(([sessionId]) => sessionId));
    try {
        for (let i = 0; i < localStorage.length; i += 1) {
            const key = localStorage.key(i);
            if (key?.startsWith(KEY_PREFIX)) ids.add(key.slice(KEY_PREFIX.length));
        }
    } catch {
        // In-memory paragraphs are still available when storage is not.
    }
    return [...ids];
};

// crypto.randomUUID only exists on secure pages, and home may be reached over plain http.
const paragraphId = () => {
    if (crypto.randomUUID) return crypto.randomUUID();
    const bytes = crypto.getRandomValues(new Uint8Array(16));
    return [...bytes].map((byte) => byte.toString(16).padStart(2, "0")).join("");
};

const announce = (name, detail) => window.dispatchEvent(new CustomEvent(name, {detail}));

export const unsavedParagraphs = (sessionId) => read(sessionId);

export const queueParagraph = (storyId, sessionId, text) => {
    const paragraphs = read(sessionId);
    paragraphs.push({id: paragraphId(), story: String(storyId), text});
    write(sessionId, paragraphs);
    announce(CHANGED_EVENT, {sessionId: String(sessionId)});
};

const csrfToken = () => document.querySelector('meta[name="csrf-token"]')?.content;

const send = (url, method, paragraph) => fetch(url, {
    method,
    credentials: "same-origin",
    headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": csrfToken() || ""
    },
    body: JSON.stringify({writing_session: {text: paragraph.text}, paragraph_id: paragraph.id})
});

// Sends one session's paragraphs in order. Stops at the first that does not get through,
// so nothing is saved out of order; it is tried again later.
const sendSession = async (sessionId) => {
    let currentId = sessionId;
    for (;;) {
        const [paragraph] = read(currentId);
        if (!paragraph) return;

        const base = `/stories/${paragraph.story}/writing_sessions`;
        let response = await send(`${base}/${currentId}.json`, "PATCH", paragraph);

        // The session was deleted elsewhere: keep the words in a new session in the same story.
        if (response.status === 404) {
            response = await send(`${base}.json`, "POST", paragraph);
            if (!response.ok) return;
            const {id} = await response.json();
            const newId = String(id);
            const memoryOnly = memoryQueues.has(currentId);
            const [, ...rest] = read(currentId);
            write(currentId, []);
            write(newId, [...read(newId), ...rest], memoryOnly);
            announce(MOVED_EVENT, {from: currentId, to: newId, story: paragraph.story});
            currentId = newId;
            continue;
        }

        if (!response.ok) return;

        const remaining = read(currentId).filter((queued) => queued.id !== paragraph.id);
        write(currentId, remaining);
        announce(CHANGED_EVENT, {sessionId: currentId, saved: paragraph.id});
    }
};

// A call while a round is under way asks for one more round, so a paragraph queued for
// another session during it is not left waiting for the timer.
let sendAgain = false;

export const sendUnsaved = async () => {
    if (sending) {
        sendAgain = true;
        return;
    }
    sending = true;
    try {
        do {
            sendAgain = false;
            for (const sessionId of sessionIds()) {
                try {
                    await sendSession(sessionId);
                } catch {
                    // Home is out of reach; everything stays queued for the next try.
                }
            }
        } while (sendAgain);
    } finally {
        sending = false;
    }
};

window.addEventListener("online", sendUnsaved);
document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible") sendUnsaved();
});
document.addEventListener("turbo:load", sendUnsaved);
setInterval(sendUnsaved, RETRY_INTERVAL_MS);
