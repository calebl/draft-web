import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "device"];

  // Fills the hidden device fields as the note is sent, so layout feedback arrives with the context to reproduce it.
  describeDevice() {
    const visible = window.visualViewport;
    const values = {
      user_agent: navigator.userAgent,
      width: window.innerWidth,
      height: window.innerHeight,
      visible_width: visible ? Math.round(visible.width) : "",
      visible_height: visible ? Math.round(visible.height) : "",
      pixel_ratio: window.devicePixelRatio,
      standalone: window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true,
    };
    this.deviceTargets.forEach((input) => {
      input.value = values[input.dataset.field] ?? "";
    });
  }

  open() {
    this.dialogTarget.showModal();
  }

  close() {
    this.dialogTarget.close();
  }
}
