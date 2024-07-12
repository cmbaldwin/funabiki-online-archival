import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  connect() {
    this.togglePriceVisibility();
  }

  togglePriceVisibility() {
    const priceToggle = document.querySelector('#price-toggle-form .form-check-input');
    if (priceToggle && priceToggle.checked) { this.element.classList.remove('d-none') };
  }

}