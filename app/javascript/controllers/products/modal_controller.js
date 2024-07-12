import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  connect() {
  }

  disconnect() {
  }

  showProductModal(_event) {
    const productModal = document.querySelector('#productModal');
    const modal = bootstrap.Modal.getOrCreateInstance(productModal, {
      keyboard: false
    });
    modal.show();
  }
}