import { Controller } from "@hotwired/stimulus";
import $ from "jquery";
import {CHANGED_EVENT, MOVED_EVENT, queueParagraph, sendUnsaved, unsavedParagraphs} from "controllers/unsaved_paragraphs";

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
        this.unsavedNoteTarget.hidden = paragraphs.length === 0;
        this.updateCount();
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
        const saved = event.detail.saved &&
            this.unsavedTarget.querySelector(`[data-paragraph-id="${event.detail.saved}"]`);
        if (saved) {
            saved.classList.remove("unsaved");
            this.savedTextTarget.appendChild(saved);
            this.savedHereWords += countWords(saved.textContent);
        }
        this.renderUnsaved();
        if (this.isAtBottom) this.scrollToBottom();

        // Everything is home: show the saved session as home has it, unless a paragraph is
        // being typed, which a refresh would clear.
        if (saved && this.unsavedTarget.childElementCount === 0 && this.textTarget.value === "") {
            window.Turbo.visit(window.location.href, {action: "replace"});
        }
    }

    // The session was deleted elsewhere and its waiting paragraphs went to a new one.
    handleUnsavedMoved(event) {
        if (event.detail.from !== this.sessionId) return;

        window.Turbo.visit(`/stories/${event.detail.story}/writing_sessions/${event.detail.to}/edit`, {action: "replace"});
    }

    submit(event) {
        const {textTarget} = this;

        this.updateCount();

        if (event.key === "Enter" || event.keyCode === 13) {
            event.preventDefault();

            if (textTarget.value === "") return;

            try {
                queueParagraph(this.element.dataset.storyId, this.sessionId, textTarget.value);
            } catch {
                // The phone could not keep it: send it straight away as before.
                $(document).find(event.target).closest('form').find("input[type=submit]").trigger("click");
                return;
            }
            textTarget.value = "";
            this.renderUnsaved();
            this.scrollToBottom();
            this.isAtBottom = true;
            sendUnsaved();
        }
    }
}

const countWords = (text) => text.split(/\s+/).filter(Boolean).length;