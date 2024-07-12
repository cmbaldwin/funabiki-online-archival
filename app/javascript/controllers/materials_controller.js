import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static instance;
  static targets = [];

  connect() {
  }

  disconnect() {
  }

  openModal(event) {
    const materialModalEl = document.getElementById('materialModal');
    const modal = bootstrap.Modal.getOrCreateInstance(materialModalEl)
    modal.show();
  }
}