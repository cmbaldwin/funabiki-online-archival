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

    // Okayama page
    // Subtotal/Price Calculations
    // HINASE
    const hinaseVolumes = document.querySelectorAll('.hinase_volume');
    const hinaseSubtotalInput = document.querySelector('#hinase_subtotal');
    const hinasePrice = parseFloat(document.querySelector('#hinase_price').value);
    const hinaseInvoiceInput = document.querySelector('#hinase_invoice');
    var hinase_volume_total = 0;
    hinaseVolumes.forEach(function (volume) {
      hinase_volume_total += parseFloat(volume.value);
    });
    hinaseSubtotalInput.value = hinase_volume_total.toFixed(1);
    hinaseInvoiceInput.value = Math.round(hinasePrice * hinase_volume_total * tax);

    // IRI
    const iriVolumes = document.querySelectorAll('.iri_volume');
    const iriSubtotalInput = document.querySelector('#iri_subtotal');
    const iriAvgPrice = document.querySelector('#iri_avg_price');
    const iriInvoiceInput = document.querySelector('#iri_invoice');
    let iriVolumeSubtotal = 0;
    let iriInvoiceTotal = 0;
    iriVolumes.forEach(function (volumeCell) {
      const volume = parseFloat(volumeCell.value);
      const supplier = volumeCell.dataset.supplier;
      const price = parseFloat(document.querySelector(`.iri_price[data-supplier="${supplier}"]`).value);
      iriVolumeSubtotal += volume;
      iriInvoiceTotal += volume * price;
      const with_tax_price = Math.round(volume * price * tax);
      document.querySelector(`.iri_invoice_subtotal[data-supplier="${supplier}"]`).innerHTML = with_tax_price;
    });
    const iriAvgPrice_val = iriVolumeSubtotal == 0 ? 0 : Math.round(iriInvoiceTotal / iriVolumeSubtotal);
    iriAvgPrice.value = iriAvgPrice_val;
    iriSubtotalInput.value = iriVolumeSubtotal.toFixed(1);
    iriInvoiceInput.value = Math.round(iriVolumeSubtotal * iriAvgPrice.value * tax);

    // TAMATSU
    // Tamatsu Large
    const tamatsuVolumes = document.querySelectorAll('.tamatsu_volume');
    let tamatsuVolumeSubtotal = 0;
    let tamatsuTotal = 0;
    tamatsuVolumes.forEach(function (volumeCell) {
      const volume = parseFloat(volumeCell.value);
      tamatsuVolumeSubtotal += volume;
      const supplier = volumeCell.dataset.supplier;
      const price = parseFloat(document.querySelector(`.tamatsu_price[data-supplier="${supplier}"]`).value);
      const preTaxSubtotal = (volume * price);
      const with_tax_price = Math.round(preTaxSubtotal * tax);
      tamatsuTotal += with_tax_price;
      document.querySelector(`.tamatsu_invoice_subtotal[data-supplier="${supplier}"]`).innerHTML = with_tax_price;
    });
    // Tamatsu Small
    const tamatsoSmallVolumes = document.querySelectorAll('.tamatsu_small_volume');
    const tamatsuSmallPrice = parseFloat(document.querySelector('#tamatsu_small_price').value);
    let tamatsuSmallVolumeSubtotal = 0;
    let tamatsuSmallTotal = 0;
    tamatsoSmallVolumes.forEach(function (volumeCell) {
      const volume = parseFloat(volumeCell.value);
      tamatsuSmallVolumeSubtotal += volume;
      const preTaxSubtotal = (volume * tamatsuSmallPrice);
      const with_tax_price = Math.round(preTaxSubtotal * tax);
      tamatsuSmallTotal += with_tax_price;
    });
    // Tamatsu subtotals/totals
    const tamatsuSmallVolumeSubtotalInput = document.querySelector('#tamatsu_small_volume_subtotal');
    tamatsuSmallVolumeSubtotalInput.innerHTML = Math.round(tamatsuSmallVolumeSubtotal);
    const tamatsuInvoice = document.querySelector('#tamatsu_invoice');
    tamatsuInvoice.value = Math.round(tamatsuTotal + tamatsuSmallTotal);
    const subtotalInput = document.querySelector('#tamatsu_big_subtotal');
    subtotalInput.innerHTML = Math.round(tamatsuVolumeSubtotal);
    const allSubtotalInput = document.querySelector('#tamatsu_subtotal');
    allSubtotalInput.value = (tamatsuVolumeSubtotal + tamatsuSmallVolumeSubtotal).toFixed(1);
    const tamatsuAverage = tamatsuVolumeSubtotal == 0 ? 0 : Math.round(tamatsuTotal / tamatsuVolumeSubtotal);
    const tamatsuAvgPriceInput = document.querySelector('#tamatsu_avg_price');
    tamatsuAvgPriceInput.value = Math.round(tamatsuAverage);

    // MUSHIAGE
    const mushiageVolumes = document.querySelectorAll('.mushiage_volume');
    let mushiageVolumeTotal = 0;
    let mushiageTotal = 0;
    let mushiageTaxTotal = 0;
    mushiageVolumes.forEach(function (volumeCell) {
      const supplier = volumeCell.dataset.supplier;
      const volume = parseFloat(volumeCell.value);
      mushiageVolumeTotal += volume;
      const price = parseFloat(document.querySelector(`.mushiage_price[data-supplier="${supplier}"]`).value);
      const preTaxSubtotal = (volume * price);
      mushiageTotal += preTaxSubtotal;
      const with_tax_price = Math.round(preTaxSubtotal * tax);
      mushiageTaxTotal += with_tax_price;
      const subtotalCell = document.querySelector(`.mushiage_subtotal[data-supplier="${supplier}"]`);
      subtotalCell.innerHTML = with_tax_price;
    });
    document.getElementById('mushiage_volume_subtotal').value = mushiageVolumeTotal;
    const mushiageAvgPrice = mushiageVolumeTotal == 0 ? 0 : Math.round(mushiageTotal / mushiageVolumeTotal);
    document.getElementById('mushiage_per_kilo_price').innerHTML = mushiageAvgPrice;
    document.getElementById('mushiage_pre_tax_subtotal').innerHTML = mushiageTotal;
    document.getElementById('mushiage_invoice').value = mushiageTaxTotal;

    // OKAYAMA VOLUME TOTAL
    const okayamaVolumeTotal = hinase_volume_total + iriVolumeSubtotal + tamatsuVolumeSubtotal + tamatsuSmallVolumeSubtotal + mushiageVolumeTotal;
    document.querySelector('#okayama_grand_total').innerHTML = Math.round(okayamaVolumeTotal);

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
