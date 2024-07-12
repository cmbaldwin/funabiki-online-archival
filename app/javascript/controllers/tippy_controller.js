import { Controller } from "@hotwired/stimulus";

import "tippy.js";

export default class extends Controller {
  tippyInstance;
  static targets = [];

  connect() {
    this.tippyInstance = this.initTippy(this.element);
  }

  initTippy(element) {
    // Basic options for all tooltips
    const defaultOptions = {
      allowHTML: true,
      duration: [300, 0],
      touch: "hold",
      followCursor: true,
    };

    // Merge options: basicOptions <- dataOptions <- expCardOptions (if exp_card class is present)
    const options = {
      ...defaultOptions,
      ...(element.classList.contains("exp_card") && this.expCardOptions())
    };

    return tippy(element, options);
  }

  expCardOptions() {
    // Options specific to exp_card
    const expCardOptions = {
      animation: 'scale',
      theme: 'exp_card',
      placement: 'bottom'
    };
    return expCardOptions;
  }

  disconnect() {
    this.tippyInstance.destroy();
  }

}
