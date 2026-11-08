// Keeps the phone's list of recent stories (id and title only) and the page theme, so the
// offline writing page can offer them while Draft cannot reach home. Refreshed whenever an
// online page loads.

export const STORIES_KEY = "draft.recentStories";
export const THEME_KEY = "draft.theme";

const remember = () => {
    try {
        const stories = document.body?.dataset.recentStories;
        if (stories) localStorage.setItem(STORIES_KEY, stories);
        const theme = document.body?.dataset.theme;
        if (theme) localStorage.setItem(THEME_KEY, theme);
    } catch {
        // Without storage the offline page simply has no stories to offer.
    }
};

document.addEventListener("turbo:load", remember);
remember();
