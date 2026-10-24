import { Controller } from "@hotwired/stimulus";
import $ from "jquery";

export default class extends Controller {
    static targets = ["text", "count", "textView", "form", "headerActions"];

    connect() {
        this.handleScroll = this.handleScroll.bind(this);
        this.handleViewportResize = this.handleViewportResize.bind(this);
        this.scrollToBottom();
        this.isAtBottom = true;
        this.textViewTarget.addEventListener("scroll", this.handleScroll);
        window.addEventListener("resize", this.handleViewportResize);
        window.visualViewport?.addEventListener("resize", this.handleViewportResize);
        window.visualViewport?.addEventListener("scroll", this.handleViewportResize);
        this.fitToVisibleViewport();
    }

    disconnect() {
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

    submit(event) {
        const {textTarget, countTarget} = this;

        const $count = $(countTarget);
        const originalCount = parseInt(countTarget.getAttribute('data-original-count'));
        const inProgress = textTarget.value.split(/\s+/).length;

        $count.text(`${originalCount + inProgress}`);

        if (event.key === "Enter" || event.keyCode === 13) {
            event.preventDefault();

            if (textTarget.value === "") return;

            $(document).find(event.target).closest('form').find("input[type=submit]").trigger("click");
        }
    }
}