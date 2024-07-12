import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['input', 'price'];

  connect() {
    this.supplierColumn = this.inputTarget.closest('.supplier-column');
    this.targetFrame = document.getElementById('supply_entry_frame');
    this.supplyTypeVariation = this.element.form.dataset.supplyTypeVariation;
    this.supplyType = this.element.form.dataset.supplyType;
    this.updateSubtotals();
    this.disableLoadingOverlay();
  }

  disableLoadingOverlay() {
    // check for any .supply-input-spinner elements, if there are none, remove .loading_overlay
    if (!this.targetFrame.querySelector('.supply-input-spinner')) {
      const loadingOverlays = document.querySelectorAll('.loading_overlay');
      loadingOverlays.forEach(overlay => overlay.remove());
    }
  }

  updateSubtotals() {
    this.updateLineSubtotal();
    this.updateSupplierSupplyTypeVariationSubtotal();
    this.updateSupplyTypeVariationSubtotal();
    this.updateSupplyTypeSubtotal()
  }

  updateLineSubtotal() {
    // get index of self as inputs from closest .supplier-column, and find that same index within all supplier columns, add them together and put it in the same index on .subtotal-column
    const index = Array.from(this.supplierColumn.querySelectorAll('form')).indexOf(this.inputTarget.form);
    const supplierColumns = Array.from(this.targetFrame.querySelectorAll('.supplier-column'));
    const lineSubtotal = supplierColumns.reduce((subtotal, column) => {
      const value = parseFloat(column.querySelectorAll('input.quantity.form-control')[index]?.value);
      return value ? subtotal + value : subtotal;
    }, 0);
    const subtotalSpan = this.targetFrame.querySelector('.subtotal-column').querySelectorAll('span.supply-type-variation-line-subtotal')[index];
    subtotalSpan.textContent = lineSubtotal.toFixed(1);
    this.nearestHandle(subtotalSpan).classList.remove('bg-success');
  }

  nearestHandle(element) {
    return element.closest('.input-group').querySelector('.handle');
  }

  updateSupplierSupplyTypeVariationSubtotal() {
    // get supply type variation from form dataset, find all inputs with same supply type variation, add them together and put it in the same index on .supplier-column
    const supplyTypeVariationSelector = `span.supplier-supply-type-variation-subtotal[data-supply-type-variation="${this.supplyTypeVariation}"]`;
    const supplierTypeVariationSpan = this.supplierColumn.querySelector(supplyTypeVariationSelector)
    const supplyTypeVariationSubtotal = Array.from(this.supplierColumn.querySelectorAll(`form[data-supply-type-variation="${this.supplyTypeVariation}"] input.quantity.form-control`)).reduce((subtotal, input) => {
      const value = parseFloat(input.value);
      return value ? subtotal + value : subtotal;
    }, 0);
    supplierTypeVariationSpan.textContent = supplyTypeVariationSubtotal.toFixed(1);
    this.nearestHandle(supplierTypeVariationSpan).classList.remove('bg-success');
  }

  updateSupplyTypeVariationSubtotal() {
    // get supply type variation from form dataset, find all inputs with same supply type variation, add them together and put it in the same index on .supplier-column
    const supplyTypeVariationSelector = `span.supply-type-variation-subtotal[data-supply-type-variation="${this.supplyTypeVariation}"]`;
    const supplyTypeVariationSpan = this.targetFrame.querySelector(supplyTypeVariationSelector);
    const supplyTypeVariationInputs = this.targetFrame.querySelectorAll(`form[data-supply-type-variation="${this.supplyTypeVariation}"] input.quantity.form-control`);
    const supplierTypeVariationSubtotal = Array.from(supplyTypeVariationInputs).reduce((subtotal, input) => {
      const value = parseFloat(input.value);
      return value ? subtotal + value : subtotal;
    }, 0);
    supplyTypeVariationSpan.textContent = supplierTypeVariationSubtotal.toFixed(1);
    this.nearestHandle(supplyTypeVariationSpan).classList.remove('bg-success');
  }

  updateSupplyTypeSubtotal() {
    // get supply type from form dataset, find all inputs with same supply type, add them together and put it in the same index on .supplier-column
    const supplyTypeSelector = `span.supply-type-subtotal[data-supply-type="${this.supplyType}"]`;
    const supplyTypeSpan = this.targetFrame.querySelector(supplyTypeSelector);
    const supplyTypeSubtotal = Array.from(this.targetFrame.querySelectorAll(`form[data-supply-type="${this.supplyType}"] input.quantity.form-control`)).reduce((subtotal, input) => {
      const value = parseFloat(input.value);
      return value ? subtotal + value : subtotal;
    }, 0);
    supplyTypeSpan.textContent = supplyTypeSubtotal.toFixed(1);
    this.nearestHandle(supplyTypeSpan).classList.remove('bg-success');
  }
}