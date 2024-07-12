import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['salePriceInput', 'buyerSalesNav', 'incompleteBuyer']

  connect() {
  }

  buyerSalesNavTargetConnected() {
    this.tryToFindIncompleteInput(3);
  }

  tryToFindIncompleteInput(attempts) {
    let firstIncompleteInput = this.salePriceInputTargets.find(element => element.value == 0);
    if (firstIncompleteInput) {
      firstIncompleteInput.focus();
      firstIncompleteInput.select();
    } else if (attempts > 0) {
      const firstIncompleteBuyer = this.incompleteBuyerTargets[0];
      if (firstIncompleteBuyer) {
        firstIncompleteBuyer.click();
        // Wait for the new page to load, then try again
        setTimeout(() => this.tryToFindIncompleteInput(attempts - 1), 300);
      }
    }
  }

  salePriceInputTargetConnected(element) {
    this.togglePriceWarning(element)
    element.addEventListener('keyup', () => {
      this.togglePriceWarning(element)
    })
  }

  salePriceInputTargetDisconnected(element) {
    element.removeEventListener('keyup', () => {
      this.togglePriceWarning(element)
    })
  }

  togglePriceWarning(element) {
    // if the value is 0, add a warning class
    if (element.value == 0) {
      element.classList.add('bg-warning')
    } else {
      element.classList.remove('bg-warning')
    }
  }

  toggleActiveLink(event) {
    // find closest .nav
    const nav = event.target.closest('.nav');
    // find all .btn-outline-light
    const navLinks = nav.querySelectorAll('.btn-outline-light');
    // remove active class from all .btn-outline-light
    navLinks.forEach((link) => {
      link.classList.remove('active');
    });
    // add active class to clicked link
    event.target.closest('.btn-outline-light').classList.add('active');
  }
}