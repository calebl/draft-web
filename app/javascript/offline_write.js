// The page shown while Draft cannot reach home: pick a recent story and write a new session.
// Its paragraphs wait in the same queue as any other unsaved paragraph, under a temporary
// session id. When home is reachable again the session is created and the rest follow.

import { Application } from "@hotwired/stimulus";
import ComposeController from "controllers/compose_controller";
import {CHANGED_EVENT, MOVED_EVENT, OFFLINE_PREFIX, offlineSessionId, unsavedSessions} from "controllers/unsaved_paragraphs";

const STORIES_KEY = "draft.recentStories";
const THEME_KEY = "draft.theme";

const readStored = (key, fallback) => {
    try {
        return JSON.parse(localStorage.getItem(key)) ?? fallback;
    } catch {
        return fallback;
    }
};

const applyTheme = () => {
    let theme;
    try {
        theme = localStorage.getItem(THEME_KEY);
    } catch {
        // Fall back to the phone's own setting.
    }
    if (theme !== "light" && theme !== "dark") {
        theme = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
    }
    document.body.dataset.theme = theme;
    document.querySelector('meta[name="theme-color"]')
        ?.setAttribute("content", theme === "dark" ? "#101010" : "#ffffff");
};

const picker = document.querySelector("[data-offline-picker]");
const storiesList = document.querySelector("[data-offline-stories]");
const composeTemplate = document.querySelector("[data-offline-compose]");

const storyTitle = (storyId) => {
    const story = readStored(STORIES_KEY, []).find(({id}) => String(id) === String(storyId));
    return story ? story.title : "A story";
};

const storyCard = (title, actionLabel, onClick, detail) => {
    const card = document.createElement("div");
    card.className = "story";
    const heading = document.createElement("h3");
    heading.textContent = title;
    card.appendChild(heading);
    if (detail) {
        const note = document.createElement("p");
        note.className = "offline-waiting";
        note.textContent = detail;
        card.appendChild(note);
    }
    const actions = document.createElement("div");
    actions.className = "story-actions";
    const button = document.createElement("a");
    button.href = "#";
    button.textContent = actionLabel;
    button.addEventListener("click", (event) => {
        event.preventDefault();
        onClick();
    });
    actions.appendChild(button);
    card.appendChild(actions);
    return card;
};

const plural = (count, word) => `${count} ${word}${count === 1 ? "" : "s"}`;

// Sessions written here that home has not received yet come first, so they stay visible
// and can be continued.
const renderPicker = () => {
    const waiting = unsavedSessions()
        .filter(({sessionId}) => sessionId.startsWith(OFFLINE_PREFIX))
        .map(({sessionId, storyId, count, rejected}) => storyCard(
            storyTitle(storyId),
            "Keep writing",
            () => openSession(storyId, sessionId),
            rejected
                ? "Home couldn't save this"
                : `${plural(count, "paragraph")} not saved yet`
        ));
    const stories = readStored(STORIES_KEY, [])
        .map(({id, title}) => storyCard(title, "Write", () => openSession(id, offlineSessionId())));

    storiesList.replaceChildren(...waiting, ...stories);
    if (!waiting.length && !stories.length) {
        document.querySelector("[data-offline-message]").textContent =
            "Draft can't reach home. Check your connection and try again.";
    }
};

let openPage = null;

const closeSession = () => {
    openPage?.remove();
    openPage = null;
    picker.hidden = false;
    renderPicker();
};

function openSession(storyId, sessionId) {
    picker.hidden = true;
    openPage = composeTemplate.content.firstElementChild.cloneNode(true);
    const compose = openPage.querySelector('[data-controller="compose"]');
    compose.dataset.storyId = String(storyId);
    compose.dataset.sessionId = sessionId;
    openPage.querySelector("[data-offline-done]").addEventListener("click", closeSession);
    document.body.appendChild(openPage);
}

applyTheme();
renderPicker();

// New Session or Write sent here from a story: start that story's session straight away.
const pickedStory = new URLSearchParams(window.location.search).get("story");
if (pickedStory && /^\d+$/.test(pickedStory)) openSession(pickedStory, offlineSessionId());
window.addEventListener(CHANGED_EVENT, () => { if (!openPage) renderPicker(); });
window.addEventListener(MOVED_EVENT, () => { if (!openPage) renderPicker(); });

const application = Application.start();
application.register("compose", ComposeController);
