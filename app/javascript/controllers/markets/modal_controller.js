import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
  static targets = [];

  connect() {
    this.CSRFtoken = document.querySelector('meta[name="csrf-token"]').content;
    this.marketModalEl = document.querySelector('#marketModal');
    this.marketModal = bootstrap.Modal.getOrCreateInstance(this.marketModalEl, {
      keyboard: false
    });
    this.marketModalEl.addEventListener('hidden.bs.modal', (_event) => {
      this.refreshMarkets();
    });
  }

  refreshMarkets() {
    // return unless there is a turbo_frame with the id 'markets' (e.g. if we're editing on a profits page)
    if (!document.getElementById('markets')) return;

    const url = this.marketModalEl.dataset.reloadPath;
    Turbo.visit(url, { frame: 'markets', action: 'replace', stream: true });
  }

  disconnect() {
  }

  showMarketModal(_event) {
    this.marketModal.show();
  }
}