import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  connect() {
    // fade out element after 4 seconds
    setTimeout(() => {
      this.element.classList.add("d-none");
    }, 3000);
  }

}
