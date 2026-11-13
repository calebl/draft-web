import { Controller } from "@hotwired/stimulus";
import $ from "jquery";
import {
    CHANGED_EVENT, MOVED_EVENT, REJECTED, SERVER_ERROR,
    queueParagraph, sendUnsaved, unsavedParagraphs, unsavedProblem
} from "controllers/unsaved_paragraphs";

// Matches the fade of a paragraph still waiting (sessions/edit.scss).
const UNSAVED_NOTE_DELAY_MS = 600;

// When home answered with an error, the connection is not to blame.
const UNSAVED_NOTES = {
    [REJECTED]: "Home couldn't save this. The words are kept on this phone.",
    [SERVER_ERROR]: "Home couldn't save this yet. Will try again."
};

export default class extends Controller {
    static targets = ["text", "count", "textView", "form", "headerActions", "unsaved", "unsavedNote", "savedText"];

    connect() {
        this.handleScroll = this.handleScroll.bind(this);
        this.handleViewportResize = this.handleViewportResize.bind(this);
        this.handleUnsavedChanged = this.handleUnsavedChanged.bind(this);
        this.handleUnsavedMoved = this.handleUnsavedMoved.bind(this);
        this.savedHereWords = 0;
        this.renderUnsaved();
        window.addEventListener(CHANGED_EVENT, this.handleUnsavedChanged);
        window.addEventListener(MOVED_EVENT, this.handleUnsavedMoved);
        // Size to the visible area before scrolling: after saving, the page comes back while
        // the keyboard is still open, and scrolling first would leave the newest line hidden
        // below the shrunken text.
        this.fitToVisibleViewport();
        this.scrollToBottom();
        this.isAtBottom = true;
        // Saving swaps in a new composer while the keyboard is still open. Focus it without
        // scrolling: an iPhone otherwise scrolls the page to centre the newly focused field,
        // and the whole writing screen jumps up until it is pinned back to the visible area.
        this.textTarget.focus({preventScroll: true});
        this.textViewTarget.addEventListener("scroll", this.handleScroll);
        window.addEventListener("resize", this.handleViewportResize);
        window.visualViewport?.addEventListener("resize", this.handleViewportResize);
        window.visualViewport?.addEventListener("scroll", this.handleViewportResize);
    }

    disconnect() {
        clearTimeout(this.noteTimer);
        this.noteTimer = null;
        window.removeEventListener(CHANGED_EVENT, this.handleUnsavedChanged);
        window.removeEventListener(MOVED_EVENT, this.handleUnsavedMoved);
        this.textViewTarget.removeEventListener("scroll", this.handleScroll);
        window.removeEventListener("resize", this.handleViewportResize);
        window.visualViewport?.removeEventListener("resize", this.handleViewportResize);
        window.visualViewport?.removeEventListener("scroll", this.handleViewportResize);
    }

    // An on-screen keyboard shrinks the visible area without shrinking the page, and the
    // browser scrolls the page to keep the composer in view, pushing the header off screen.
    // Pin the writing screen to exactly the visible area so the header stays on top and the
    // text and composer share what is left above the keyboard.
    fitToVisibleViewport() {
        const viewport = window.visualViewport;
        if (!viewport) return;

        this.element.style.setProperty("--visible-top", `${viewport.pageTop}px`);
        this.element.style.setProperty("--visible-height", `${viewport.height}px`);
    }

    scrollToBottom() {
        const {textViewTarget} = this;
        textViewTarget.scrollTop = textViewTarget.scrollHeight;
    }

    handleScroll() {
        const {textViewTarget} = this;
        this.isAtBottom = textViewTarget.scrollHeight - textViewTarget.clientHeight - textViewTarget.scrollTop <= 1;
    }

    handleViewportResize() {
        this.fitToVisibleViewport();
        if (this.isAtBottom) this.scrollToBottom();
    }

    get sessionId() {
        return this.element.dataset.sessionId;
    }

    // Shows the paragraphs still waiting on the phone, faded, under the saved text.
    renderUnsaved() {
        const paragraphs = unsavedParagraphs(this.sessionId);
        this.unsavedTarget.replaceChildren(...paragraphs.map((paragraph) => {
            const div = document.createElement("div");
            div.className = "unsaved";
            div.dataset.paragraphId = paragraph.id;
            div.textContent = paragraph.text;
            return div;
        }));
        this.unsavedNoteTarget.textContent = UNSAVED_NOTES[unsavedProblem(this.sessionId)] || this.waitingNote;
        this.updateUnsavedNote(paragraphs.length > 0);
        this.updateCount();
    }

    // The page's own note, shown while the paragraphs wait for the connection.
    get waitingNote() {
        this.originalNote ??= this.unsavedNoteTarget.textContent;
        return this.originalNote;
    }

    // The note waits a moment, so a save that comes straight back never shows it. It takes
    // room under the text, and showing it only to hide it again would push the text up and
    // drop it straight back down.
    updateUnsavedNote(waiting) {
        if (!waiting) {
            clearTimeout(this.noteTimer);
            this.noteTimer = null;
            this.unsavedNoteTarget.hidden = true;
        } else if (this.unsavedNoteTarget.hidden && !this.noteTimer) {
            this.noteTimer = setTimeout(() => {
                this.noteTimer = null;
                this.unsavedNoteTarget.hidden = false;
                if (this.isAtBottom) this.scrollToBottom();
            }, UNSAVED_NOTE_DELAY_MS);
        }
    }

    // The count includes paragraphs not saved yet and the one being typed.
    updateCount() {
        const queued = unsavedParagraphs(this.sessionId)
            .reduce((total, paragraph) => total + countWords(paragraph.text), 0);
        const originalCount = parseInt(this.countTarget.getAttribute('data-original-count')) || 0;
        $(this.countTarget).text(`${originalCount + this.savedHereWords + queued + countWords(this.textTarget.value)}`);
    }

    handleUnsavedChanged(event) {
        if (event.detail.sessionId !== this.sessionId) return;

        // A paragraph home just saved joins the saved text until the page is refreshed.
        const saved = this.markSaved(event.detail.saved);
        this.renderUnsaved();
        if (this.isAtBottom) this.scrollToBottom();
        if (saved) this.visitSavedSessionIfReady();
    }

    // A temporary or deleted session's waiting paragraphs went to a new session.
    handleUnsavedMoved(event) {
        if (event.detail.from !== this.sessionId) return;

        this.markSaved(event.detail.saved);
        this.element.dataset.sessionId = String(event.detail.to);
        this.savedSessionUrl = `/stories/${event.detail.story}/writing_sessions/${event.detail.to}/edit`;
        this.renderUnsaved();
        if (this.isAtBottom) this.scrollToBottom();
        this.visitSavedSessionIfReady();
    }

    markSaved(paragraphId) {
        const saved = paragraphId &&
            this.unsavedTarget.querySelector(`[data-paragraph-id="${paragraphId}"]`);
        if (!saved) return false;

        saved.classList.remove("unsaved");
        this.savedTextTarget.appendChild(saved);
        this.savedHereWords += countWords(saved.textContent);
        return true;
    }

    visitSavedSessionIfReady() {
        if (this.unsavedTarget.childElementCount === 0 && this.textTarget.value === "") {
            visit(this.savedSessionUrl || window.location.href);
        }
    }

    submit(event) {
        const {textTarget} = this;

        this.updateCount();

        if (event.key === "Enter" || event.keyCode === 13) {
            event.preventDefault();

            if (textTarget.value === "") return;

            queueParagraph(this.element.dataset.storyId, this.sessionId, textTarget.value);
            textTarget.value = "";
            this.renderUnsaved();
            this.scrollToBottom();
            this.isAtBottom = true;
            sendUnsaved();
        }
    }
}

// The offline writing page runs without Turbo.
const visit = (url) => {
    if (window.Turbo) window.Turbo.visit(url, {action: "replace"});
    else window.location.replace(url);
};

const countWords = (text) => text.split(/\s+/).filter(Boolean).length;