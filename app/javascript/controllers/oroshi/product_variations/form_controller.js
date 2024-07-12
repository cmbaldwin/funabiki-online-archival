import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['packagingSelectCheckbox'];

  connect() {
  }

  updatePackagings(event) {
    const productId = event.target.value;
    // for each packagingSelectCheckboxTarget check if the dataset productId is equal to the selected productId
    // if so, or if the id is nil, remove d-none if not add d-none
    this.packagingSelectCheckboxTargets.forEach((packagingSelectCheckbox) => {
      const checkboxProductId = packagingSelectCheckbox.dataset.productId;
      if (checkboxProductId === productId || checkboxProductId === "") {
        packagingSelectCheckbox.classList.remove('d-none');
      } else {
        packagingSelectCheckbox.classList.add('d-none');
      }
    });
  }
}
