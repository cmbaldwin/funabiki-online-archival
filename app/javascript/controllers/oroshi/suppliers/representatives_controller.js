import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  addRepresentative(event) {
    // Get the first representative field
    let firstField = this.element.querySelector('.representative');

    // Clone the first field
    let newField = firstField.cloneNode(true);

    // Clear the value of the new field
    newField.querySelector('input').value = '';

    // Append the new field to the parent element
    firstField.parentNode.appendChild(newField);
  }

  removeRepresentative(event) {
    let representativeFields = this.element.querySelectorAll('.representative');
    // only remove if it's the not the only field
    if (representativeFields.length > 1) {
      representativeFields[representativeFields.length - 1].remove();
    };
  }
}