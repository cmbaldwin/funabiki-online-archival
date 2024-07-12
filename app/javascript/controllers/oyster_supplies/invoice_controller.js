import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  copy(event) {
    navigator.clipboard.writeText(event.target.textContent).then(() => {
      // Success feedback here
    }, () => {
      // Failure feedback here
    });
  }

  resetModal(_event) {
    // look for #supplyModal, if it exists, close it
    // find #supply_action_partial with it and replace it with empty string
    const modal = document.getElementById('supplyModal');
    if (modal) {
      const modalInstance = bootstrap.Modal.getOrCreateInstance(modal);
      modalInstance.hide();
    }
  }

}