import { Controller } from "@hotwired/stimulus";


export default class extends Controller {
  static targets = ['form', 'newForm'];

  connect() {
    this.CSRFtoken = document.querySelector('[name="csrf-token"]').content;
    this.manageFormEventListeners('add');
    this.newFormTarget.addEventListener('keyup', (e) => this.newFormListener(e));
  }

  disconnect() {
    this.manageFormEventListeners('remove');
    this.newFormTarget.removeEventListener('keyup', (e) => this.newFormListener(e));
  }

  manageFormEventListeners(action) {
    this.formTargets.forEach((form) => {
      const eventHandler = (e) => {
        e.preventDefault();
        this.submitForm(e.target);
      };

      if (action === 'add') {
        form.addEventListener('change', eventHandler);
      } else if (action === 'remove') {
        form.removeEventListener('change', eventHandler);
      }
    });
  }

  submitForm(el) {
    const form = el.closest('form');
    const form_data = new FormData(form);
    // bootstrap warning message around turbo-frame within form
    const turboFrame = document.querySelector(`#${form.dataset.turboFrame}`);
    console.log(turboFrame)
    turboFrame.classList.add('border', 'rounded', 'border-warning');
    fetch(form.action, {
      method: 'PATCH',
      body: form_data,
      headers: {
        'X-CSRF-Token': this.CSRFtoken,
        'X-Requested-With': 'XMLHttpRequest'
      },
      credentials: 'same-origin'
    })
      .then(response => {
        turboFrame.classList.remove('border-warning');
        if (response.ok) {
          turboFrame.classList.add('border-success')
        } else {
          turboFrame.classList.add('border-danger')
          throw new Error('Network response was not ok.');
        }
      })
      .then(setTimeout(() => {
        turboFrame.classList.remove('border', 'rounded', 'border-success');
      }, 1000)
      )
  }

  destroyProductType(event) {
    event.preventDefault();
    const data = event.currentTarget.dataset;
    const confirmMessage = data.turboConfirm;
    if (!window.confirm(confirmMessage)) {
      return;
    }
    const url = data.url;
    fetch(url, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': this.CSRFtoken,
        'X-Requested-With': 'XMLHttpRequest'
      },
      credentials: 'same-origin'
    })
      .then(response => response.text())
      .then(body => Turbo.renderStreamMessage(body))
  }



  newFormListener(event) {
    {
      // if all form fields, select and input, have values enable submit button
      const form = event.target.closest('form');
      const submitButton = form.querySelector('[type="submit"]');
      const name = form.querySelector('#ec_product_type_name');
      const counter = form.querySelector('#ec_product_type_counter');
      let allFieldsHaveValues = true;
      [name, counter].forEach((input) => {
        (input.value === '') ? allFieldsHaveValues = false : null;
      })
      allFieldsHaveValues ? (submitButton.disabled = false) : (submitButton.disabled = true);
    }
  }

}
