import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['input'];

  connect() {
    this.addListeners();

    // If the controller is loaded but there are no inputs found, observe when they are added
    const observer = new MutationObserver(() => {
      if (this.hasInputTarget) {
        this.addListeners();
        observer.disconnect()
      }
    })
    observer.observe(this.element, { childList: true, subtree: true })
  }

  addListeners() {
    this.inputTargets.forEach((input) => {
      this.inputWarningsListener(input)
      this.priceWarningsListener(input)
      this.nextInputListener(input)
    })
    this.focusNext()
  }

  // Focus on first text box on intilization
  focusNext() {
    this.toggleMarketIndicator()
    const toFocus = this.inputTargets.find(input => input.classList.contains('bg-warning')) || this.inputTargets[0]
    toFocus?.focus()
  }

  // Toggles active market nav pill
  toggleMarketIndicator() {
    const marketId = this.element.dataset.marketId
    // Remove all formating from all market links
    document.querySelectorAll('#market-pills a').forEach(function (el) { el.classList.remove('active', 'animate__animated', 'animate__pulse', 'animate__infinite') })
    // Add formating to active market link
    const currentMarket = document.querySelector(`.nav-link[data-market-id="${marketId}"]`)
    currentMarket.classList.add('active', 'animate__animated', 'animate__pulse', 'animate__infinite');
  }


  inputWarningsListener(input) {
    this.toggleWarning(input)
    input.addEventListener('focusout', () => {
      this.toggleWarning(input)
    })
  }

  // Toggle warning class on input where pair is empty
  toggleWarning(input) {
    const pairedInput = document.getElementById(input.dataset.pairedInput)
    if (!pairedInput) return;

    if (input.value !== '' && pairedInput.value === '') {
      pairedInput.classList.add('bg-warning')
    } else if (input.value === '' && pairedInput.value !== '') {
      input.classList.add('bg-warning')
    } else {
      input.classList.remove('bg-warning')
    }
  }

  priceWarningsListener(input) {
    this.togglePriceWarningBorder(input)
    input.addEventListener('focusout', () => {
      this.togglePriceWarningBorder(input)
    })
  }

  togglePriceWarningBorder(input) {
    const averagePrice = input.dataset.averagePrice
    const currentValue = input.value
    if (currentValue > 0) {
      if ((currentValue > averagePrice * 1.3) || (currentValue < averagePrice * 0.7)) {
        input.classList.add('border', 'rounded', 'border-warning')
      } else {
        input.classList.remove('border', 'rounded', 'border-warning')
      }
    }
  }

  // Enter on the form goes to the next input or loads the next market
  nextInputListener(input) {
    input.addEventListener('keyup', (e) => {
      if (e.key !== 'Enter') return;

      this.autosave()
      const pairedInput = document.getElementById(input.dataset.pairedInput)
      if ((pairedInput) && (pairedInput?.value === '')) return pairedInput.focus();

      const warningInputs = [...this.inputTargets.filter(input => input.classList.contains('bg-warning'))]
      if (warningInputs.length === 0) return this.nextMarket();

      if (!input.classList.contains('bg-warning')) return warningInputs[0].focus();

      const nextElIndex = warningInputs.indexOf(input) + 1;
      if (!warningInputs[nextElIndex]) return this.nextMarket();

      warningInputs[nextElIndex].focus();
    })
    input.addEventListener('blur', () => {
      this.autosave()
    })
  }

  CSRFtoken() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')
    return csrfToken.value
  }

  // autosave the form (on focusout)
  autosave(formData) {
    const url = this.element.dataset.autosaveUrl
    formData ??= new FormData(document.getElementById('edit_profit_partial_form'))
    fetch(url, {
      method: 'PATCH',
      body: formData,
      headers: {
        'X-CSRF-Token': this.CSRFtoken(),
      }
    })
      .then(() => this.updateCompletion())
      .catch(error => console.error('Error:', error));
  }

  // Updates the completion status of the profit for the corresponding partial
  updateCompletion() {
    const url = this.element.dataset.updateCompletionUrl
    fetch(url, {
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': this.CSRFtoken()
      }
    })
      .then(response => response.text())
      .then(body => Turbo.renderStreamMessage(body))
  }

  // Fetches the next market with unfilled inputs
  nextMarket() {
    const url = this.element.dataset.nextMarketUrl
    fetch(url, {
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': this.CSRFtoken()
      }
    })
      .then(response => response.text())
      .then(body => Turbo.renderStreamMessage(body))
  }
}
