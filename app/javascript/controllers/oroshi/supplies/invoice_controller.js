import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['email', 'supplierOrganizationSelect', 'sendEmailSwitch', 'sendAtInput'];

  connect() {
    this.toggleSendAtInput();
    this.updateEmailList();
  }

  disconnect() {
    // close the modal unless the parent turbo-frame id is new_invoice (because it's being replaced with a persisted invoice)
    const parentTurboFrame = this.element.closest('turbo-frame')
    if (parentTurboFrame && (parentTurboFrame?.id !== 'new_invoice')) {
      this.closeModal();
    }
  }

  updateEmailList(_event) {
    // Event target is a multiple select form input, find the selected options, they have organization_id as value
    // Use this to find emailTargets with the same data-supplier-organization-id, and remove d-none class
    // If the option is not selected, add d-none class to the emailTargets
    const selectedOptions = this.supplierOrganizationSelectTarget.selectedOptions;
    const emailTargets = this.emailTargets;
    emailTargets.forEach(emailTarget => {
      const supplierOrganizationId = emailTarget.dataset.supplierOrganizationId;
      if (Array.from(selectedOptions).some(option => option.value === supplierOrganizationId)) {
        emailTarget.classList.remove('d-none');
      } else {
        emailTarget.classList.add('d-none');
      }
    });
  }

  toggleSendAtInput(_event) {
    const sendAtInput = this.sendAtInputTarget;
    (this.sendEmailSwitchTarget.checked) ? sendAtInput.classList.remove('d-none') : sendAtInput.classList.add('d-none');
  }

  copy(event) {
    if (navigator && navigator.clipboard) {
      navigator.clipboard.writeText(event.target.textContent).then(() => {
        // console.log('Copied to clipboard');
      }, () => {
        // console.log('Failed to copy to clipboard');
      });
    } else {
      console.log('Clipboard API not available');
    }
  }

  setLoading(_event) {
    const targetElement = this.element.querySelector(`.invoice-form`)
    targetElement?.insertAdjacentHTML('afterbegin', loading_overlay)
  }

  closeModal() {
    // close the bootstrap modal
    const modal = document.getElementById('supplyModal')
    if (modal) {
      const modalInstance = bootstrap.Modal.getInstance(modal)
      modalInstance.hide()
    }
  }
}