import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['formInput', 'form'];

  connect() {
    this.formInputTargets.forEach((input) => {
      this.formTarget.innerHTML += `<input type="hidden" name="${input.name}" value="${input.value}">`;
      input.addEventListener('change', this.modifyForm.bind(this));
    });
  }

  disconnect() {
  }

  modifyForm(event) {
    const input = event.target;
    const existingInput = this.formTarget.querySelector(`input[name="${input.name}"]`);

    existingInput.value = input.value;
  }

  submit() {
    Turbo.navigator.submitForm(this.formTarget);
  }
}
