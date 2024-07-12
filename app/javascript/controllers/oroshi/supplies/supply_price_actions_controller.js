import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['priceForm', 'suppliersSelect'];

  connect() {
    this.priceFormTarget.addEventListener('submit', this.enableFields.bind(this))
    this.controlRemoveSectionBtn();
  }

  disconnect() {
    this.priceFormTarget.removeEventListener('submit', this.enableFields.bind(this));
  }

  enableFields(event) {
    event.preventDefault();
    const tabPanes = this.element.querySelectorAll('.tab-pane');
    tabPanes.forEach((tabPane) => {
      tabPane.classList.add('active', 'show');
    });
    // Append window.loading_overlay to the front of #supply_action_partial
    const turboFrame = document.getElementById('supply_modal_content');
    turboFrame.insertAdjacentHTML('afterbegin', window.loading_overlay);
    Turbo.navigator.submitForm(this.priceFormTarget);
  }

  addSection(event) {
    const tabPane = event.target.closest('.tab-pane');
    const priceCards = Array.from(tabPane.querySelectorAll('.price_card'));
    const priceCard = priceCards.find((priceCard) => priceCard.classList.contains('d-none'));
    priceCard.classList.remove('d-none');
    this.controlRemoveSectionBtn([tabPane]);
  }

  removeSection(event) {
    const tabPane = event.target.closest('.tab-pane');
    const priceCards = Array.from(tabPane.querySelectorAll('.price_card'));
    const priceCard = priceCards.reverse().find((priceCard) => !priceCard.classList.contains('d-none'));
    priceCard.querySelectorAll('input').forEach((input) => input.value = null);
    priceCard.querySelectorAll('option').forEach((option) => option.selected = false);
    priceCard.classList.add('d-none');
    this.controlRemoveSectionBtn([tabPane]);
  }

  controlRemoveSectionBtn(tabPanes = null) {
    tabPanes ??= this.element.querySelectorAll('.tab-pane');
    tabPanes.forEach((tabPane) => {
      const removeSectionBtn = tabPane.querySelector('#remove-section');
      const addSectionBtn = tabPane.querySelector('#add-section');
      const priceCards = Array.from(tabPane.querySelectorAll('.price_card'));
      const visiblePriceCards = priceCards.filter((priceCard) => !priceCard.classList.contains('d-none'));
      const hiddenPriceCards = priceCards.filter((priceCard) => priceCard.classList.contains('d-none'));

      removeSectionBtn ? removeSectionBtn.classList.toggle('d-none', visiblePriceCards.length <= 1) : null;
      addSectionBtn ? addSectionBtn.classList.toggle('d-none', hiddenPriceCards.length === 0) : null;
      this.selectSupplier();
    });
  }

  selectSupplier() {
    // when a supplier is selected in any suppliersSelectTargets, remove that option from all other suppliersSelectTargets
    // when a supplier is deselected in any suppliersSelectTargets, add that option back to all other suppliersSelectTargets
    const selectedOptionValues = this.selectedOptionValues();
    this.suppliersSelectTargets.forEach((suppliersSelect) => {
      suppliersSelect.querySelectorAll('option').forEach((option) => {
        // if an option is not in the list of selected options, enable it
        const currentlySelected = selectedOptionValues.includes(option.value);
        // return if the option is already disabled or selected
        if (option.selected) return;

        !currentlySelected ? option.disabled = false : option.disabled = true;
      });
    });
  }

  selectedOptionValues() {
    let selectedOptions = [];
    this.suppliersSelectTargets.forEach((suppliersSelect) => {
      // if the current suppliersSelect is not visible, deselect all options
      if (suppliersSelect.classList.contains('d-none')) return;

      selectedOptions = [...selectedOptions, ...suppliersSelect.selectedOptions];
    });
    return [...new Set(selectedOptions.map((selectedOption) => selectedOption.value))];
  }

  copyPrice(event) {
    // find the target label and get the priceType and priceIndex
    const currentLabel = event.target
    const priceType = currentLabel.dataset.priceType;
    const supplierOrganizationId = currentLabel.dataset.supplierOrganizationId;
    // find the first price input and get the price to copy
    const firstPriceInput = this.element.querySelector(`[name="[prices][${supplierOrganizationId}][0][basket_prices][${priceType}]"`); // like: [name="[prices][supplier_organization_id][basket_id][basket_prices][${priceType}]
    const price = firstPriceInput.value;
    // return if the price is empty
    if (price === '') return;

    // find the next input located right after currentLabel
    const currentInput = currentLabel.nextElementSibling;
    // set the price
    currentInput.value = price;
  }
}