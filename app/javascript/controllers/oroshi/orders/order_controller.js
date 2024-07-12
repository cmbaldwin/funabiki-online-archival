import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
  static targets = ['quantityInput', 'activeOrderOverlay', 'orderTitleModalLink', 'orderFormSubmit']

  connect() {
    this.itemQuantityInput = this.quantityInputTargets.find(input => input.id.includes('item_quantity'));
    this.receptacleQuantityInput = this.quantityInputTargets.find(input => input.id.includes('receptacle_quantity'));
    this.freightQuantityInput = this.quantityInputTargets.find(input => input.id.includes('freight_quantity'));
    this.orderModal = document.getElementById('orderModal');
    this.warnIfQuantityIsZero();
  }

  toggleOrderOverlay() {
    this.activeOrderOverlayTarget.classList.toggle('hidden');

    const [itemValue, receptacleValue, freightValue] = this.quantityInputTargets.map(input => input.value);

    setTimeout(() => {
      const [newItemValue, newReceptacleValue, newFreightValue] = this.quantityInputTargets.map(input => input.value);

      if (itemValue === newItemValue && receptacleValue === newReceptacleValue && freightValue === newFreightValue) {
        this.activeOrderOverlayTarget.classList.toggle('hidden');
      }
    }, 10000);
  }

  toggleQuantityInput(event) {
    // if the event target is not disabled just select all contents of the input and return
    if (event.target.hasAttribute('readonly')) {
      // turn readonly on for all quantityInputTargets, and add background-color: #f8f9fa;
      this.quantityInputTargets.forEach(input => {
        input.readOnly = true;
        input.style.backgroundColor = '#e0e0e0';
      });
      // turn readonly off for the event target
      event.target.readOnly = false;
      event.target.style.backgroundColor = '';
    }
    event.target.select();
  }

  updateQuantityInputs(event) {
    const dataset = this.element.dataset
    const defaultFreightBundleQuantity = parseInt(dataset.defaultFreightBundleQuantity)
    const estimatePerBoxQuantity = parseInt(dataset.estimatePerBoxQuantity)
    const target = event.target;

    switch (target.id) {
      case '_oroshi_order_item_quantity':
        const itemQuantity = parseInt(target.value);
        this.setContainerCount(estimatePerBoxQuantity, defaultFreightBundleQuantity, itemQuantity);
        this.setFreightCount(estimatePerBoxQuantity, defaultFreightBundleQuantity, itemQuantity);
        break;
      case '_oroshi_order_receptacle_quantity':
        const containerQuantity = parseInt(target.value);
        this.setItemCount(estimatePerBoxQuantity, defaultFreightBundleQuantity, containerQuantity);
        this.setFreightCount(estimatePerBoxQuantity, defaultFreightBundleQuantity, null, containerQuantity);
        break;
      case '_oroshi_order_freight_quantity':
        const freightQuantity = parseInt(target.value);
        this.setItemCount(estimatePerBoxQuantity, defaultFreightBundleQuantity, null, freightQuantity);
        this.setContainerCount(estimatePerBoxQuantity, defaultFreightBundleQuantity, null, freightQuantity);
        break;
    }
    this.warnIfQuantityIsZero();
  }

  warnIfQuantityIsZero() {
    this.quantityInputTargets.forEach(input => {
      if (parseInt(input.value) === 0) {
        input.classList.add('bg-warning');
      } else {
        input.classList.remove('bg-warning');
      }
    });
  }

  setContainerCount(estimatePerBoxQuantity, defaultFreightCount, itemQuantity = null, freightQuantity = null) {
    if (itemQuantity !== null) {
      this.receptacleQuantityInput.value = Math.ceil(itemQuantity / estimatePerBoxQuantity);
    } else if (freightQuantity !== null) {
      this.receptacleQuantityInput.value = Math.ceil(freightQuantity * defaultFreightCount);
    }
  }

  setFreightCount(estimatePerBoxQuantity, defaultFreightCount, itemQuantity = null, containerQuantity = null) {
    if (itemQuantity !== null) {
      this.freightQuantityInput.value = Math.ceil(itemQuantity / estimatePerBoxQuantity) / defaultFreightCount;
    } else if (containerQuantity !== null) {
      this.freightQuantityInput.value = Math.ceil(containerQuantity / defaultFreightCount);
    }
  }

  setItemCount(estimatePerBoxQuantity, defaultFreightCount, containerQuantity = null, freightQuantity = null) {
    if (containerQuantity !== null) {
      this.itemQuantityInput.value = containerQuantity * estimatePerBoxQuantity;
    } else if (freightQuantity !== null) {
      this.itemQuantityInput.value = freightQuantity * defaultFreightCount * estimatePerBoxQuantity;
    }
  }

  CSRFtoken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    if (!meta) { return }

    return meta.getAttribute('content')
  }

  orderFormSubmit() {
    // find nearest turbo-frame with a src attribute
    const frame = this.element.closest('turbo-frame[src]');
    // get the submit button to show status with bg-color
    // submit the form via ajax
    const submitButton = this.orderFormSubmitTarget;
    submitButton.classList.remove('btn-light');
    submitButton.classList.add('bg-yellow');
    const form = this.element;
    const formData = new FormData(form);
    const url = form.getAttribute('action');
    const token = this.CSRFtoken();

    fetch(url, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': token
      },
      body: formData
    }).then(response => {
      // remove btn-light
      submitButton.classList.remove('bg-yellow');
      if (response.ok) {
        // add the bg-success class to the form with a 1 second timeout
        submitButton.classList.add('btn-success');
        // reload the closest turbo frame if reload is true
        if (frame) {
          setTimeout(() => {
            submitButton.classList.remove('btn-success');
            submitButton.classList.add('btn-light');
            frame.reload();
          }, 300);
        }
        response.text().then(stream => {
          Turbo.renderStreamMessage(stream);
        });
      } else {
        // should have json errors in the response, alert them
        response.json().then(data => {
          alert(data.errors);
        });
        submitButton.classList.add('btn-warning');
      }
    });
  }
}