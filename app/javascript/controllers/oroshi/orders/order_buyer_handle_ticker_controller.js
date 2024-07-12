import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["buyerHandle"]

  connect() {
    if (this.hasOverflow(this.buyerHandleTarget)) {
      this.buyerHandleTarget.classList.add('ticker-animation');
    }
  }

  hasOverflow(element) {
    const container = element.closest('.ticker-container');
    return container.scrollWidth > container.clientWidth;
  }
}