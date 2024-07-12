import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  connect() {
    this.element.addEventListener("DOMContentLoaded", this.calculate());
    this.keyboardSetup(this, false);
    this.element.addEventListener('inputChange', function (_event) {
      this.calculate();
    }.bind(this));
  }

  keyboardSetup(controllerInstance, teardown) {
    integerInput(controllerInstance, teardown);
  }

  disconnect() {
    this.keyboardSetup(this, true);
    this.element.removeEventListener('inputChange', function (_event) {
      this.calculate();
    }.bind(this));
  }

  calculate() {
    const parsed_tax = parseFloat(document.querySelector('#oyster_supply_oysters_tax').value);
    let tax = parsed_tax || 1.08;

    // OTHER PAGE
    const otherVolumes = document.querySelectorAll('.other_volume');
    let otherVolumeTotal = 0;
    let otherVolumeTotals = {};
    let otherInvoiceTotals = {};
    otherVolumes.forEach(function (volumeCell) {
      const number = volumeCell.dataset.number;
      const volume = parseFloat(volumeCell.value);
      const price = parseFloat(document.querySelector(`.other_price[data-number="${number}"]`).value);
      const preTaxSubtotal = (volume * price);
      const with_tax_price = Math.round(preTaxSubtotal * tax);
      otherVolumeTotal += volume;
      otherVolumeTotals[number] ? otherVolumeTotals[number] += volume : otherVolumeTotals[number] = volume;
      otherInvoiceTotals[number] ? otherInvoiceTotals[number] += with_tax_price : otherInvoiceTotals[number] = with_tax_price;
    });
    Object.entries(otherVolumeTotals).forEach(([number, volumeTotal]) => {
      document.querySelector(`.other_subtotal[data-number="${number}"]`).value = volumeTotal;
      document.querySelector(`.other_invoice[data-number="${number}"]`).value = otherInvoiceTotals[number];
    });
    document.querySelector('#hoka_grand_total').innerHTML = Math.round(otherVolumeTotal);
  }

}
