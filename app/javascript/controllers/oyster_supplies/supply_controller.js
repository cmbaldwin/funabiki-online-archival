import { Controller } from "@hotwired/stimulus";

import "tippy.js";

export default class extends Controller {
  static targets = ['volumeTotal', 'grandTotal'];

  connect() {
    this.tippySetup();
    this.calculateTotalVolume();
    this.registerObservers();
  }

  tippySetup() {
    this.tippyStats();
    this.printingOptionsTippy();
  }

  tippyStats() {
    const oysterSupplyId = document.querySelector('.genryou').dataset.id;
    // If it's nil this is a new supply, so no need to fetch stats
    if (oysterSupplyId) {
      const controllerInstance = this;
      // Tippy with Ajax
      tippy('.supply_tippy', {
        content: controllerInstance.tippyLoadingSpinner(),
        allowHTML: true,
        animation: 'scale',
        duration: [300, 0],
        interactive: true,
        placement: 'bottom',
        touch: 'hold',
        maxWidth: 'none',
        onShow(instance) {
          // only load if there is a spin-container, otherwise return
          const spinContainer = instance.popper.querySelector('.spin-container');
          if (!spinContainer) return;
          // On show get tippy stat given a supply ID (as :id) and the "stat name" (as :stat) in the data from the div where the tippy is applied
          controllerInstance.fetchTippyContents(instance, oysterSupplyId);
        },
      });
    }
  }

  tippyLoadingSpinner() {
    return `
      <div class="d-flex justify-content-center align-items-center spin-container">
        <div class="spinner-border spinner-border-sm text-primary m-4" role="status">
          <span class="visually-hidden">Loading...</span>
        </div>
      </div>
    `;
  }

  fetchTippyContents(instance, oysterSupplyId) {
    const statName = instance.reference.getAttribute('data-stat-name');
    fetch(`/oyster_supplies/tippy_stats/${oysterSupplyId}/${statName}`)
      .then(response => response.text())
      .then(result => instance.setContent(result))
      .catch((error) => {
        instance._error = error;
        instance.setContent(`エラー： ${error}`);
      })
  }

  printingOptionsTippy() {
    // Print options for Supply Checks
    // Options for only creating supply checks for specific time, instead of both simultaneously.
    // Avoid having the select to print only first or second page, and document should generate trivially faster.
    tippy('.supply_check_tippy', {
      allowHTML: true,
      interactive: true,
      animation: 'scale',
      duration: [300, 0],
      placement: 'top',
      touch: 'hold'
    });
  }

  calculateTotalVolume() {
    let volumeTotal = 0;
    this.volumeTotalTargets.forEach((element) => volumeTotal += parseInt(element.innerText))
    this.grandTotalTarget.innerText = volumeTotal;
  }

  registerObservers() {
    this.observers = this.volumeTotalTargets.map(target => {
      const observer = new MutationObserver(this.calculateTotalVolume.bind(this));
      observer.observe(target, { childList: true, subtree: true, characterData: true })
      return observer
    })
  }

  disconnect() {
    this.destroyTippys();
    this.observers.forEach(observer => observer.disconnect())
  }

  destroyTippys() {
    const supplyTippys = document.querySelectorAll('.supply_tippy')
    const supplyCheckTippy = document.querySelector('.supply_check_tippy');
    const allTippys = [...supplyTippys, supplyCheckTippy].filter(Boolean);
    allTippys.forEach((element) => {
      const tippy = element?._tippy
      if (tippy) tippy.destroy();
    });
  }
}
