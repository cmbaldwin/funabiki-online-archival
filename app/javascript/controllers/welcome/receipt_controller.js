import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  connect() {
    this.oysisCheckbox = document.getElementById('reciept_options_oysis');
    this.oysisCheckbox.addEventListener('change', event => this.toggleOysis.bind(this)(event));
  }

  disconnect() {
    this.oysisCheckbox.removeEventListener('change', event => this.toggleOysis.bind(this)(event));
  }

  toggleOysis(event) {
    const funabikiImg = document.querySelector('.funabiki_img');
    const funabikiText = document.querySelector('.funabiki_info');
    const rakutenImg = document.querySelector('.rakuten_img');
    const rakutenText = document.querySelector('.rakuten_info');

    if (event.target.checked) {
      rakutenImg.classList.remove('d-none');
      rakutenText.classList.remove('d-none');
      funabikiImg.classList.add('d-none');
      funabikiText.classList.add('d-none');
    } else {
      funabikiImg.classList.remove('d-none');
      funabikiText.classList.remove('d-none');
      rakutenImg.classList.add('d-none');
      rakutenText.classList.add('d-none');
    }
  }

  insertReceiptData(event) {
    // Basic Data
    const data = event.target.dataset;
    const amount = data.amount
    const purchaserInput = document.querySelector('#reciept_options_purchaser');
    const amountInput = document.querySelector('#reciept_options_amount');
    purchaserInput.value = data.name;
    amountInput.value = amount;

    // Tax Data Estimation (based on ¥1000 shipping estimate)
    const per8AmountInput = document.querySelector('#reciept_options_tax_8_amount');
    const per8TaxInput = document.querySelector('#reciept_options_tax_8_tax');
    const per10AmountInput = document.querySelector('#reciept_options_tax_10_amount');
    const per10TaxInput = document.querySelector('#reciept_options_tax_10_tax');
    per8AmountInput.value = (amount - 1000) - (Math.floor((amount - 1000) * 0.08));
    per8TaxInput.value = Math.floor((amount - 1000) * 0.08);
    per10AmountInput.value = 1000 - (Math.floor(1000 * 0.1));
    per10TaxInput.value = Math.floor(1000 * 0.1);

    // Oyster Sister Info
    const oysisCheckbox = document.querySelector('#reciept_options_oysis');
    oysisCheckbox.checked = true;
    this.toggleOysis();
  }
}