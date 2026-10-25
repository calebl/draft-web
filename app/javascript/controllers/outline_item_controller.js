import { Controller } from "@hotwired/stimulus"
import $ from 'jquery'

export default class extends Controller {
  static targets = ["text"];

  resize() {
    this.textTarget.style.height = "auto";
    this.textTarget.style.height = this.textTarget.scrollHeight + "px";
  }

  textTargetConnected(el) {
    el.rows = 1;
    this.resize();
  }

  submit(event){
    $(event.target).closest('form').find("input[type=submit]").trigger("click");
  }
}