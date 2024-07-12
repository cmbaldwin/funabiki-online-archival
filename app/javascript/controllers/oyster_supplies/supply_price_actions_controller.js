import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['priceForm', 'priceCard', 'suppliersSelect'];

  connect() {
    this.priceFormTarget.addEventListener('submit', this.enableFields.bind(this))
    this.supplierSelectOptionDefaults = this.suppliersSelectTargets[0].options
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
    const supplyActionPartial = document.querySelector('#supply_action_partial');
    supplyActionPartial.insertAdjacentHTML('afterbegin', window.loading_overlay);
    Turbo.navigator.submitForm(this.priceFormTarget)
  }

  addSection() {
    const priceCard = this.priceCardTargets.find((priceCard) => priceCard.classList.contains('d-none'));
    priceCard.classList.remove('d-none');
    this.controlRemoveSectionBtn();
  }

  removeSection() {
    const priceCard = this.priceCardTargets.reverse().find((priceCard) => !priceCard.classList.contains('d-none'));
    priceCard.querySelectorAll('input').forEach((input) => input.value = null);
    priceCard.querySelectorAll('option').forEach((option) => option.selected = false);
    priceCard.classList.add('d-none');
    this.controlRemoveSectionBtn();
  }

  controlRemoveSectionBtn() {
    const removeSectionBtn = this.element.querySelector('#remove-section');
    const addSectionBtn = this.element.querySelector('#add-section');
    const visiblePriceCards = this.priceCardTargets.filter((priceCard) => !priceCard.classList.contains('d-none'));
    const hiddenPriceCards = this.priceCardTargets.filter((priceCard) => priceCard.classList.contains('d-none'));

    removeSectionBtn ? removeSectionBtn.classList.toggle('d-none', visiblePriceCards.length <= 1) : null;
    addSectionBtn ? addSectionBtn.classList.toggle('d-none', hiddenPriceCards.length === 0) : null;
    this.selectSupplier();
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
    // find the first price input and get the price to copy
    const priceInput = this.element.querySelector(`[name="[prices][hyogo][0[prices][${priceType}]]"]`); // like: name="[prices][hyogo][0[prices][large]]"
    const price = priceInput.value;
    // return if the price is empty
    if (price === '') return;

    // find the next input located right after currentLabel
    const currentInput = currentLabel.nextElementSibling;
    // set the price
    currentInput.value = price;
  }
}