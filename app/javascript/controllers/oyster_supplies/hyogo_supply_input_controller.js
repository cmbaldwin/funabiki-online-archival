import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  connect() {
    this.element.addEventListener("DOMContentLoaded", this.calculate());
    this.keyboardSetup(this, false);
    this.element.addEventListener('inputChange', function (_event) {
      this.calculate();
    }.bind(this));
    // find printing options tippy tippy('.supply_check_tippy'

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
    const numbersWithCommas = (x) => {
      return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }

    // Subtotals for a subsections of types (horizontal, right end, by type)
    const subtotal_r = document.querySelectorAll('.subtotal_r');
    subtotal_r.forEach(function (element) {
      const rowColumns = element.parentNode.children;
      const col_num = rowColumns.length - 1;
      let subtotal = 0;
      Array.from(rowColumns).forEach(function (column, index) {
        if (index < col_num) {
          const current = column.querySelector('input');
          subtotal += parseFloat(current?.value || 0);
        }
      });
      element.innerHTML = subtotal;
    });

    // Subtotals for single supplier of a locale, time, type and supplier (vertical, below supplier)
    const subtotal_u = document.querySelectorAll('.subtotal_u');
    subtotal_u.forEach(function (element) {
      const input = element.querySelector('input');
      const time = input.dataset.time;
      const type = input.dataset.type;
      const supplier = input.dataset.supplier;
      const cells = document.querySelectorAll(`input[data-time="${time}"][data-type="${type}"][data-supplier="${supplier}"]`);
      let subtotal = 0;
      cells.forEach(function (element) {
        if (element.readOnly) { return };
        subtotal += parseFloat(element?.value || 0);
      });
      input.value = subtotal;
    });

    // Subtotals for all suppliers of a locale, time and type (horizontal, right end, type subtotal)
    const subtotal_ru = document.querySelectorAll('.subtotal_ru');
    subtotal_ru.forEach(function (element) {
      const locale = element.dataset.locale;
      const time = element.dataset.time;
      const type = element.dataset.type;
      const cells = document.querySelectorAll(`.subtotal_u[data-locale="${locale}"] input[data-time="${time}"][data-type="${type}"]`);
      let subtotal = 0;
      cells.forEach(function (cell) {
        subtotal += parseFloat(cell?.value || 0);
      });
      element.innerHTML = subtotal;
    });

    // Combined shucked volume subtotals by supplier and time (vertical total from subtotals)
    const muki_total = document.querySelectorAll('.muki_total');
    muki_total.forEach(function (element) {
      const locale = element.dataset.locale;
      const time = element.dataset.time;
      const supplier = element.dataset.supplier;
      const cells = document.querySelectorAll(`.subtotal_u[data-locale="${locale}"] input[data-time="${time}"][data-supplier="${supplier}"]`);
      let subtotal = 0;
      cells.forEach(function (cell) {
        subtotal += parseFloat(cell?.value || 0);
      });
      element.innerHTML = subtotal;
    });

    // Totals for locale and time (horizontal, right end, time/locale subtotal)
    const timeTotals = document.querySelectorAll('.total');
    timeTotals.forEach(function (element) {
      const locale = element.dataset.locale;
      const time = element.dataset.time;
      const cells = document.querySelectorAll(`.muki_total[data-locale="${locale}"][data-time="${time}"]`);
      let subtotal = 0;
      cells.forEach(function (cell) {
        subtotal += parseFloat(cell?.innerHTML || 0);
      });
      element.innerHTML = subtotal;
    });

    // Subtotals at the top of the page for hyogos shucked oysters
    const calculateSubtotal = (locale) => {
      const subtotals = document.querySelectorAll(`.total[data-locale="${locale}"]`);
      return Array.from(subtotals).reduce((acc, subtotal) => {
        return acc + parseFloat(subtotal.innerHTML)
      }, 0);
    };
    const [sakoshi_subtotal, aioi_subtotal] = [calculateSubtotal("sakoshi"), calculateSubtotal("aioi")]
    document.querySelector('#sakoshi_subtotal').innerHTML = Math.round(sakoshi_subtotal);
    document.querySelector('#aioi_subtotal').innerHTML = Math.round(aioi_subtotal);
    document.querySelector('#hyogo_grand_total').innerHTML = Math.round(sakoshi_subtotal + aioi_subtotal);

    // Shell totals
    const shellSubtotals = document.querySelectorAll('.shell_subtotal');
    let shellTotal = 0;
    shellSubtotals.forEach(function (element) {
      const subtotal = parseInt(element.innerHTML);
      shellTotal += subtotal;
    });
    document.querySelector('#kara_grand_total').innerHTML = shellTotal;


    // Calculate and automatically input volumes for hyogo price input page
    const volumeSubtotal = document.querySelectorAll('.volume_subtotal');
    volumeSubtotal.forEach(function (element) {
      //disable input into it's own input
      const input = element.querySelector('input');
      input.readOnly = true;
      input.classList.add('bg-secondary');
      const type = element.dataset.type;
      const supplier = element.dataset.supplier;
      const subtotals = document.querySelectorAll(`.subtotal_u  input[data-type="${type}"][data-supplier="${supplier}"]`);
      let typeTotal = 0;
      subtotals.forEach(function (subtotal) {
        typeTotal += parseFloat(subtotal?.value || 0);
      });
      element.querySelector('input').value = typeTotal;
    });

    // If Volume Subtotal isn't 0 and Price Input IS 0 (or out of range) then give a visual alert for the input
    const priceInputs = document.querySelectorAll('.price-input');
    priceInputs.forEach(function (priceInput) {
      const price = parseFloat(priceInput.querySelector('input').value);
      const volume = parseFloat(priceInput.nextElementSibling.querySelector('input').value);
      const priceLabel = priceInput.parentNode.querySelector('th').textContent;

      if (volume !== 0 && price === 0) {
        priceInput.querySelector('input').classList.add("bg-warning");
      } else {
        priceInput.querySelector('input').classList.remove("bg-warning");
      }

      if (priceLabel.includes('むき身', 0)) {
        if ((price < 500 || price > 3000) && volume !== 0) {
          priceInput.querySelector('input').classList.add("bg-warning");
        } else {
          priceInput.querySelector('input').classList.remove("bg-warning");
        }
      } else if (priceLabel.includes('殻付き〔大-個〕', 0) || priceLabel.includes('殻付き〔小-個〕', 0)) {
        if ((price < 30 || price > 100) && volume !== 0) {
          priceInput.querySelector('input').classList.add("bg-warning");
        } else {
          priceInput.querySelector('input').classList.remove("bg-warning");
        }
      } else if (priceLabel.includes('殻付き〔バラ-㎏〕', 0)) {
        if ((price < 200 || price > 800) && volume !== 0) {
          priceInput.querySelector('input').classList.add("bg-warning");
        } else {
          priceInput.querySelector('input').classList.remove("bg-warning");
        }
      }
    });

    // Extend this visual alert to the total card for each supplier
    const priceInputNames = document.querySelectorAll('.supplier_name');
    priceInputNames.forEach(function (supplierInput) {
      const supplier = supplierInput.dataset.supplier;
      let rows = document.querySelectorAll(`.supplier_prices[data-supplier="${supplier}"]`);
      let need = false;
      rows.forEach(function (row) {
        const input = row.querySelector('input');
        if (input.classList.contains('bg-warning')) {
          need = true;
        }
      });
      const card = document.querySelector(`.card[data-supplier="${supplier}"]`);
      need ? card.classList.add('border-warning') : card.classList.remove('border-warning');
    });

    // Calculate and display revenue and tax, for each supplier in a card
    const supplierTypeSubtotals = document.querySelectorAll('.type_subtotal')
    const supplierTotalHash = {};
    supplierTypeSubtotals.forEach(function (typeSubtotal) {
      const type = typeSubtotal.dataset.type;
      const supplier = typeSubtotal.dataset.supplier;
      const priceInput = document.querySelector(`.price-input[data-type="${type}"][data-supplier="${supplier}"] input`);
      const volumeInput = document.querySelector(`.volume_subtotal[data-type="${type}"][data-supplier="${supplier}"] input`);
      let subtotal = Math.round(parseFloat(priceInput.value) * parseFloat(volumeInput.value))
      typeSubtotal.innerHTML = numbersWithCommas(subtotal);
      // Accumulate the total for each supplier in a hash
      supplierTotalHash[supplier] ? supplierTotalHash[supplier] += subtotal : supplierTotalHash[supplier] = subtotal;
    });
    //  add it to the total card for each supplier .before_tax_total, .tax_subtotal and .supplier_total
    const supplierTotalCards = document.querySelectorAll('.supplier_total_card');
    supplierTotalCards.forEach(function (card) {
      const supplier = card.dataset.supplier;
      const beforeTaxTotal = card.querySelector('.before_tax_total');
      const taxSubtotal = card.querySelector('.tax_subtotal');
      const supplierTotal = card.querySelector('.supplier_total');
      beforeTaxTotal.innerHTML = numbersWithCommas(supplierTotalHash[supplier]);
      taxSubtotal.innerHTML = numbersWithCommas(Math.round(supplierTotalHash[supplier] * (tax - 1)));
      supplierTotal.innerHTML = numbersWithCommas(Math.round(supplierTotalHash[supplier] * tax));
    });
  }

}
