import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['loadProductTypesSelect', 'loadProductSelect', 'loadProductBtn'];

  connect() {
    this.loadProductTypesSelectTarget.addEventListener('change', this.toggleProductSelect.bind(this));
    this.loadProductSelectTargets.forEach((productSelect) => {
      productSelect.addEventListener('change', this.modifyProductBtnUrl.bind(this));
    });
  }

  disconnect() {
  }

  toggleProductSelect(event) {
    console.log(event.target.value);
    this.loadProductSelectTargets.forEach((productSelect) => {
      productSelect.classList.add('d-none');
    });
    // find the product select that matches the product type data-type="id"
    const productSelect = document.querySelector(`.product_select[data-type="${event.target.value}"]`);
    productSelect.classList.remove('d-none');
  }

  modifyProductBtnUrl(event) {
    const productID = event.target.value;
    this.loadProductBtnTarget.href = this.loadProductBtnTarget.href.replace(/\d+$/, productID)
  }

  loadProductData(event) {
    Turbo.navigate(event.target.href, { action: 'replace' })
  }
}
