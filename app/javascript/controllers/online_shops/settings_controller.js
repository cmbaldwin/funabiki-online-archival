import { Controller } from "@hotwired/stimulus";


export default class extends Controller {
  static targets = ['header'];

  connect() {
    this.manageEventListeners('add');
  }

  disconnect() {
    this.manageEventListeners('remove');
  }

  manageEventListeners(action) {
    this.headerTargets.forEach((input) => {
      const eventHandler = (e) => {
        e.preventDefault();
        this.submitForm(e.target);
      };

      if (action === 'add') {
        input.addEventListener('blur', eventHandler);
      } else if (action === 'remove') {
        input.removeEventListener('blur', eventHandler);
      }
    });
  }

  submitForm(el) {
    const section = el.dataset.section;
    const form = document.getElementById(section);
    const form_data = new FormData(form);
    const CSRFtoken = document.querySelector('[name="csrf-token"]').content;
    fetch(section, {
      method: 'POST',
      body: form_data,
      headers: {
        'X-CSRF-Token': CSRFtoken,
        'X-Requested-With': 'XMLHttpRequest'
      },
      credentials: 'same-origin'
    })
  }

  renderTab(event) {
    const data = event.target.dataset;
    const url = data.url;
    fetch(url, {
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': this.CSRFtoken
      }
    })
      .then(response => response.text())
      .then(body => Turbo.renderStreamMessage(body))
  }

}
