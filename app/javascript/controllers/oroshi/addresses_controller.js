import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['defaultToggle'];

  connect() {
  }

  setDefault(event) {
    if (event.target.checked == true) {
      this.defaultToggleTargets.forEach((toggle) => {
        if (toggle == event.target) return;

        toggle.checked = false
      });
    } else {
      const nonDefaultToggles = this.defaultToggleTargets.filter(toggle => toggle !== event.target);
      if (nonDefaultToggles.length > 0) {
        nonDefaultToggles[0].checked = true;
      }
    }
  }
}