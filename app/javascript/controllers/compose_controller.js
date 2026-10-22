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
    }

    disconnect() {
        this.textViewTarget.removeEventListener("scroll", this.handleScroll);
        window.removeEventListener("resize", this.handleViewportResize);
        window.visualViewport?.removeEventListener("resize", this.handleViewportResize);
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