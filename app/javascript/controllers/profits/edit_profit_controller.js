import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['form', 'refreshButton', 'marketPartial'];

  connect() {
    this.formTarget.addEventListener('submit', this.loadingOverlay.bind(this))
    this.marketCard = this.element.querySelector('#market_card')
    if (this.marketCard) {
      this.marketId = this.marketCard.dataset.marketId
      this.toggleMarkets(this.marketId);
    }
    const productModal = document.querySelector('#productModal');
    //on modal hide refresh market card partial
    productModal.addEventListener('hidden.bs.modal', (_event) => {
      this.refreshMarketPartial();
    })
  }

  refreshMarketPartial() {
    const marketPartial = this.marketPartialTarget
    marketPartial.insertAdjacentHTML('afterbegin', window.loading_overlay);
    const url = marketPartial.dataset.refreshUrl
    fetch(url, {
      headers: {
        'Accept': 'text/vnd.turbo-stream.html'
      }
    }).then(response => response.text())
      .then(body => Turbo.renderStreamMessage(body))
  }

  disconnect() {
    this.formTarget.removeEventListener('submit', this.loadingOverlay.bind(this));
  }

  loadingOverlay() {
    this.element.insertAdjacentHTML('afterbegin', window.loading_overlay);
  }

  // Action fired on clicking a market nav pill
  changeMarket(event) {
    this.marketPartialTarget.insertAdjacentHTML('afterbegin', window.loading_overlay);
    const marketId = event.target.dataset.marketId
    this.toggleMarkets(marketId)
  }

  // Toggles active market nav pill
  toggleMarkets(marketId) {
    // Remove all formating from all market links
    document.querySelectorAll('#market-pills a').forEach(function (el) { el.classList.remove('active', 'animate__animated', 'animate__pulse', 'animate__infinite') })
    // Add formating to active market link
    const currentMarket = document.querySelector(`.nav-link[data-market-id="${marketId}"]`)
    currentMarket.classList.add('active', 'animate__animated', 'animate__pulse', 'animate__infinite');
  }
}
