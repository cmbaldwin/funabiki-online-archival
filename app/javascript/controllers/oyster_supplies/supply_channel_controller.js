import { Controller } from "@hotwired/stimulus";
import { createConsumer } from "@rails/actioncable";

import "tippy.js";

export default class extends Controller {
  static targets = ['personIcon', 'personsIcon', 'input'];

  connect() {
    this.currentUsers = [];
    const consumer = createConsumer();
    this.consumer = consumer;
    this.personIcon = this.personIconTarget
    this.personsIcon = this.personsIconTarget
    this.CSRFtoken = document.querySelector('meta[name="csrf-token"]').content;
    const inputs = this.inputTargets;
    const data = this.element.dataset
    const userID = data.userId;
    const oysterSupplyId = data.id;
    if (!sessionStorage.getItem('sessionID')) {
      sessionStorage.setItem('sessionID', Date.now().toString());
    }
    this.supplyDate = data.supplyDate;
    if (!userID || isNaN(parseInt(userID))) return;

    this.subscription = consumer.subscriptions.create({ channel: "SuppliesChannel", session_id: sessionStorage.getItem('sessionID'), user: userID, oyster_supply: oysterSupplyId }, {
      connected: () => {
        console.log(`User with ID ${userID} connected to the Supplies Channel for Supply #${oysterSupplyId}...`);
      },

      disconnected: () => {
        console.log(`User with ID ${userID} disconnected from the Supplies Channel for Supply #${oysterSupplyId}...`);
      },

      received: (data) => {
        if (data.type === 'USERS') {
          this.currentUsers = data.users;
          console.log(`Currently there are ${data.users.length} users editing this Oyster Supply (${data.id}).`)
          this.updateUsers.bind(this)(data);
        } else if (data.type === 'INPUT_CHANGE') {
          this.handleInputChange.bind(this)(data)
        } else {
          console.log(data);
        }
      },
    });

    inputs.forEach((element) => {
      element.addEventListener('input', this.sendInputChange.bind(this));
    });
    this.refreshForm();
    document.querySelector('.supply_check_tippy').addEventListener('mouseenter', function () {
      this.submitForm()
    }.bind(this));
  }

  updateUsers(data) {
    this.removeTippys();
    if (data.users.length > 1) {
      this.personIcon.classList.contains('d-none') ? null : this.personIcon.classList.add('d-none')
      this.personsIcon.classList.contains('d-none') ? this.personsIcon.classList.remove('d-none') : null
      this.initTippy(this.personsIcon, `<center><b>${this.supplyDate}</b>の牡蠣供給入力表<br>現在、<b>${data.users.length}</b>人のユーザーが編集しています。</center>`)
    } else {
      this.personIcon.classList.contains('d-none') ? this.personIcon.classList.remove('d-none') : null
      this.personsIcon.classList.contains('d-none') ? null : this.personsIcon.classList.add('d-none')
      this.initTippy(this.personIcon, `<center><b>${this.supplyDate}</b>の牡蠣供給入力表を編集しているユーザーは一人だけです</center>`)
    }
  }

  initTippy(target, content) {
    tippy(target, {
      content: content,
      allowHTML: true,
      duration: [300, 0],
      touch: "hold",
      followCursor: true,
    });
  }

  removeTippys() {
    [this.personIcon, this.personsIcon].forEach((element) => {
      const tippy = element._tippy
      if (tippy) tippy.destroy();
    });
  }

  handleInputChange(data) {
    // Don't update if it's the same user that sent the update
    if (data.session_id == sessionStorage.getItem('sessionID')) return;

    const element = this.element.querySelector(data.selector)
    element.value = data.value;
    // Find the nearest parent element with one of the specified data-controller attributes
    const controllers = [
      "oyster-supplies--hyogo-supply-input",
      "oyster-supplies--okayama-supply-input",
      "oyster-supplies--other-supply-input"
    ];
    const selector = controllers.map(controller => `[data-controller="${controller}"]`).join(', ');
    const parent = element.closest(selector);
    if (parent) {
      // Dispatch a custom event
      const event = new CustomEvent('inputChange', { detail: data });
      parent.dispatchEvent(event);
    }
    this.refreshForm();
  }

  disconnect() {
    this.inputTargets.forEach((element) => {
      element.removeEventListener('input', this.sendInputChange.bind(this));
    });
    this.consumer.subscriptions.remove(this.subscription);
    this.removeTippys();
    // Submit form to save any unsaved changes (shouldn't be any), but also calculated subtotals
    this.submitForm();
  }

  sendInputChange(event) {
    const element = event.target
    const digPoint = element.dataset.digPoint
    const selector = `input[name="${element.name}"]`
    // Keep value as is unless it's a number
    let value;
    if (element.type === 'number') {
      value = (element.value) ? parseFloat(element.value).toString() : '0'
    } else {
      value = element.value
    }
    this.subscription.send({
      session_id: sessionStorage.getItem('sessionID'), type: 'INPUT_CHANGE', dig_point: digPoint, selector: selector, value: value
    })
    this.refreshForm();
  }

  refreshForm() {
    this.form = document.querySelector('form.edit_oyster_supply');
  }

  submitForm() {
    console.log('Submitting form...')
    if (this.form) {
      const formData = new FormData(this.form)
      fetch(this.form.action, {
        method: 'PATCH',
        body: formData,
        headers: {
          'X-CSRF-Token': this.CSRFtoken,
        }
      })
        .then(console.log('Form submitted successfully'))
        .catch(error => console.error(error))
    } else {
      console.error('Form was not initialized, updated, or found')
    }
  }
}
