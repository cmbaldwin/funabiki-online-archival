import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    'buyerSelect', 'buyerColorCircleContainer', 'shippingDate',
    'shippingMethodSelect', 'shippingMethodOption',
    'productSelect', 'productVariationOption', 'productVariationSelect', 'productionDatesSection',
    'shippingReceptacleSelect', 'shippingReceptacleEstimatePerBoxQuantity', 'shippingReceptacleDefaultFreightCount',
    'quantityLinkToggle', 'quantityInput', 'shippingCostInput', 'materialsCostInput',
    'bundledOrderSwitch', 'bundledWithOrderSelectContainer', 'bundledOrderSelectContainer', 'bundledOrderSelect',
    'bundledShippingReceptacleSwitch', 'bundledShippingReceptacleSwitchContainer', 'buyerOptionalCostSwitch',
    'quantitiesInputSection', 'salesCostsSection', 'templateWarning'
  ];

  connect() {
    this.itemQuantityInput = this.quantityInputTargets.find(input => input.id === 'oroshi_order_item_quantity');
    this.receptacleQuantityInput = this.quantityInputTargets.find(input => input.id === 'oroshi_order_receptacle_quantity');
    this.freightQuantityInput = this.quantityInputTargets.find(input => input.id === 'oroshi_order_freight_quantity');
    this.updateBuyerColor({ target: this.buyerSelectTarget });
    this.toggleProductVariations(true);
  }

  updateBuyerColor(event) {
    // find the dataset.color of the currently selected option
    const buyerColor = event.target.selectedOptions[0].dataset.color;
    // if there is no color, reset to #808080
    const color = buyerColor ? buyerColor : '#808080';
    // within the container is a .buyer-color-circle, set its background color to the color
    this.buyerColorCircleContainerTarget
      .querySelector('.buyer-color-circle').style.backgroundColor = color;
  }

  toggleShippingMethods() {
    // get buyer id from this.buyerSelectTarget selected option
    const select = this.shippingMethodSelectTarget;
    const tippyTarget = select.closest('.flex-column');
    const buyerId = this.buyerSelectTarget.selectedOptions[0].value;
    let hasOptions = false;
    this.shippingMethodOptionTargets.forEach(option => {
      // for each shippingMethodOptionTarget check the dataset buyers to get buyer ids (seperated by ',')
      const buyerIds = option.dataset.buyers.split(',');
      // if the buyer id is in the list of buyer ids, enable the option, otherwise disable it
      if (buyerIds.includes(buyerId)) {
        option.disabled = false;
        option.style.display = 'block';
        tippyTarget.dataset.tippyContent = '';
        hasOptions = true;
      } else {
        option.disabled = true;
        option.style.display = 'none';
      }
    });
    // if no options are available, disable the select, otherwise enable it and select the first option
    select.disabled = !hasOptions;
    if (hasOptions) {
      const values = this.shippingMethodOptionTargets.filter(target => !target.disabled)
      select.value = values[0].value
    };
  }

  setBuyerOrdersForBundledOrderSelect() {
    // get buyer id from this.buyerSelectTarget selected option
    const buyerId = this.buyerSelectTarget.selectedOptions[0].value;
    if (!buyerId) { return }

    // get the buyer orders from the endpoint
    const date = this.shippingDateTarget.dataset.date;
    const orderId = this.element.dataset.orderId;
    fetch(`/oroshi/buyers/${buyerId}/orders/${date}`)
      .then(response => response.json())
      // for each order, create an option and append it to this.bundledShippingReceptacleSwitchTarget
      .then(data => {
        const optionsSelect = this.bundledOrderSelectTarget
        // the first option should be the default option
        const defaultOption = optionsSelect.firstElementChild;
        // remove any existing options
        optionsSelect.innerHTML = '';
        optionsSelect.appendChild(defaultOption);
        // add back the default option
        // render json: { orders: orders.map { |order| [order.id, order.to_s] } }
        data.orders.forEach(order => {
          if (order[0] === parseInt(orderId)) { return }

          const option = document.createElement('option');
          option.value = order[0];
          option.text = order[1];
          optionsSelect.appendChild(option);
          this.loading(false);
        });
      })
      .catch(error => {
        console.error('Error:', error);
        this.loading(false);
      });
  }

  toggleProductVariations(init = false) {
    // get product id from this.productSelectTarget selected option
    const productId = this.productSelectTarget.selectedOptions[0].value;
    let hasOptions = false;
    // for each productVariationOptionTarget check the dataset product to get the product id
    this.productVariationOptionTargets.forEach(option => {
      // if the selected product id is the same as the option product id, enable the option, otherwise disable it
      if (option.dataset.product === productId) {
        option.disabled = false;
        option.style.display = 'block';
        hasOptions = true;
      } else {
        option.disabled = true;
        option.style.display = 'none';
      }
    });
    // if no options are available, disable the select, otherwise enable it and select the first option
    this.productVariationSelectTarget.disabled = !hasOptions;
    if (hasOptions && !init) {
      this.productVariationSelectTarget.value = this.productVariationOptionTargets[0].value;
    };
    this.toggleShippingReceptacle();
  }

  toggleShippingReceptacle() {
    // get default_shipping_receptacle_id from this.productVariationSelectTarget selected option
    const select = this.shippingReceptacleSelectTarget;
    const selectedOption = this.productVariationOptionTargets.find(option => option.selected);
    // if there is no selectedOption disable the select and return
    if (selectedOption) {
      select.disabled = false;
      const defaultShippingReceptacle = selectedOption.dataset.defaultShippingReceptacle;
      // select the default_shipping_receptacle_id from the options
      select.value = defaultShippingReceptacle;
    } else {
      select.disabled = true;
      select.value = '';
    }
    this.updateShippingReceptacleDefaults();
    this.toggleProductionDatesSection();
  }

  updateShippingReceptacleDefaults() {
    // get the selected option from this.shippingReceptacleSelectTarget
    const selectedOption = this.shippingReceptacleSelectTarget.selectedOptions[0];
    // if there is no selectedOption return or the value is an empty string, return
    if (!selectedOption || !selectedOption.value) { return }

    // get the estimate_item_count from the endpoint
    const productVariationId = this.productVariationSelectTarget.value;

    this.loading(true);
    fetch(
      `/oroshi/shipping_receptacles/${selectedOption.value}/estimate_per_box_quantity/${productVariationId}`)
      .then(response => response.json())
      // set the value of this.shippingReceptacleEstimateItemCountTarget to the estimate_item_count
      .then(data => {
        this.shippingReceptacleEstimatePerBoxQuantityTarget.innerHTML = data.estimate_per_box_quantity
        this.loading(false);
      })
      .catch(error => {
        console.error('Error:', error);
        this.loading(false);
      });
    // get the default_freight_count from the selected option
    const defaultFreightCount = selectedOption.dataset.defaultFreightBundleQuantity;
    // set the value of this.shippingReceptacleDefaultFreightCountTarget to the default_freight_count
    this.shippingReceptacleDefaultFreightCountTarget.innerHTML = defaultFreightCount;
    this.toggleQuantitiesInputSection();
  }

  toggleProductionDatesSection() {
    // if a productVariation is selected, remove d-none from this.productionDatesSectionTarget
    if (this.productVariationSelectTarget.value) {
      this.productionDatesSectionTarget.classList.remove('d-none');
    } else {
      this.productionDatesSectionTarget.classList.add('d-none');
    }
  }

  toggleQuantitiesInputSection() {
    // if a productVariation is slected and a shippingReceptacle is selected, remove d-none from this.quantitiesInputSectionTarget
    if (this.productVariationSelectTarget.value && this.shippingReceptacleSelectTarget.value) {
      this.quantitiesInputSectionTarget.classList.remove('d-none');
    } else {
      this.quantitiesInputSectionTarget.classList.add('d-none');
    }
  }

  toggleQuantityLink() {
    // if quantityLinkToggleTarget is checked, disable all quantityInputTargets, then enable only the center one
    if (this.quantityLinkToggleTarget.checked) {
      this.quantityInputTargets.forEach((input, index) => {
        input.readOnly = true;
        input.style.backgroundColor = '#f8f9fa';
        if (index === 1) {
          input.readOnly = false;
          input.style.backgroundColor = '';
        }
      });
    } else {
      // if quantityLinkToggleTarget is not checked, enable all quantityInputTargets
      this.quantityInputTargets.forEach(input => {
        input.readOnly = false;
        input.style.backgroundColor = '';
      });
    }
  }

  toggleQuantityInput(event) {
    // if the event target is not disabled just select all contents of the input and return
    if (event.target.hasAttribute('readonly')) {
      // turn readonly on for all quantityInputTargets, and add background-color: #f8f9fa;
      this.quantityInputTargets.forEach(input => {
        input.readOnly = true;
        input.style.backgroundColor = '#f8f9fa';
      });
      // turn readonly off for the event target
      event.target.readOnly = false;
      event.target.style.backgroundColor = '';
    }
    event.target.select();
  }

  updateQuantityInputs(event) {
    // if (this.quantityLinkToggleTarget.checked) return, else calculate the other quantities based on defaults
    if (!this.quantityLinkToggleTarget.checked) { return this.updateShippingCost() };

    const target = event.target;
    // get the defaultFreightCount from this.shippingReceptacleDefaultFreightCountTarget
    const defaultFreightCount = parseInt(this.shippingReceptacleDefaultFreightCountTarget.innerHTML);
    // get the estimatePerBoxQuantity from this.shippingReceptacleEstimateItemCountTarget
    const estimatePerBoxQuantity = parseInt(this.shippingReceptacleEstimatePerBoxQuantityTarget.innerHTML);
    // get the value of the target input
    // iterate through quantity input types to determine calculate that needs to be made
    switch (target.id) {
      case 'oroshi_order_item_quantity':
        const itemQuantity = parseInt(target.value);
        this.setContainerCount(estimatePerBoxQuantity, defaultFreightCount, itemQuantity);
        this.setFreightCount(estimatePerBoxQuantity, defaultFreightCount, itemQuantity);
        break;
      case 'oroshi_order_receptacle_quantity':
        const containerQuantity = parseInt(target.value);
        this.setItemCount(estimatePerBoxQuantity, defaultFreightCount, containerQuantity);
        this.setFreightCount(estimatePerBoxQuantity, defaultFreightCount, null, containerQuantity);
        break;
      case 'oroshi_order_freight_quantity':
        const freightQuantity = parseInt(target.value);
        this.setItemCount(estimatePerBoxQuantity, defaultFreightCount, null, freightQuantity);
        this.setContainerCount(estimatePerBoxQuantity, defaultFreightCount, null, freightQuantity);
        break;
    }
    this.updateShippingCost();
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

  toggleBundledOptions(event) {
    // if the event target is checked then remove d-none from this.bundledShippingReceptacleSwitchTarget
    if (event.target.checked) {
      this.bundledOrderSelectContainerTarget.classList.remove('d-none');
      this.bundledShippingReceptacleSwitchContainerTarget.classList.remove('d-none');
    } else {
      this.bundledOrderSelectContainerTarget.classList.add('d-none');
      this.bundledShippingReceptacleSwitchContainerTarget.classList.add('d-none');
    }
    this.updateShippingCost();
  }

  updateShippingCost() {
    // If there is no shippingReceptacleQuantity, or it's 0, return
    const shippingReceptacleQuantity = parseInt(this.receptacleQuantityInput.value);
    const freightQuantity = parseInt(this.freightQuantityInput.value);
    if (!shippingReceptacleQuantity) { return };

    // If the bundledOrderSwitch is checked set shippingCostInputTarget.value to 0 and return
    if (this.bundledOrderSwitchTarget.checked) {
      this.shippingCostInputTarget.value = '0.00';
      this.updateMaterialsCost(this.itemQuantityInput.value, shippingReceptacleQuantity, freightQuantity);
      return;
    }

    // Get the buyer data from the selected option
    const buyerData = this.buyerSelectTarget.selectedOptions[0].dataset;
    const buyerHandlingCost = parseFloat(buyerData.handlingCost);
    const buyerOptionalCost = this.buyerOptionalCostSwitchTarget.checked ? parseFloat(buyerData.optionalCost) : 0;
    // Get the shipping method data from the selected option
    const shippingMethodData = this.shippingMethodSelectTarget.selectedOptions[0].dataset;
    const perShippingReceptacleCost = parseFloat(shippingMethodData.perShippingReceptacleCost);
    const perFreightCost = parseFloat(shippingMethodData.perFreightCost);
    // Calculate the total shipping cost
    const perReceptacleShippingCost = buyerHandlingCost + buyerOptionalCost + perShippingReceptacleCost;
    const receptacleShippingCost = perReceptacleShippingCost * shippingReceptacleQuantity;
    const freightCost = perFreightCost * freightQuantity;
    const totalCost = receptacleShippingCost + freightCost;
    // Set the shipping cost input to the total cost
    this.shippingCostInputTarget.value = totalCost.toFixed(2);
    // Update the materials cost
    this.updateMaterialsCost(this.itemQuantityInput.value, shippingReceptacleQuantity, freightQuantity);
  }

  updateMaterialsCost(itemQuantity, shippingReceptacleQuantity, freightQuantity) {
    // if bundledShippingReceptacleSwitch is checked shippingReceptacleMaterialSubtotal is 0
    let shippingReceptacleMaterialSubtotal = 0;
    if (!this.bundledShippingReceptacleSwitchTarget.checked) {
      // Get the shipping receptacle cost from the selected option, calculate the subtotal
      const shippingReceptacleData = this.shippingReceptacleSelectTarget.selectedOptions[0].dataset;
      const shippingReceptacleCost = parseFloat(shippingReceptacleData.cost);
      shippingReceptacleMaterialSubtotal = shippingReceptacleCost * shippingReceptacleQuantity;
    }
    // Get the product_variation packaging cost from the selected option
    const productVariationData = this.productVariationSelectTarget.selectedOptions[0].dataset;
    const packagingCost = parseFloat(productVariationData.packagingCost);
    const packagingCostSubtotal = packagingCost * itemQuantity;
    // Endpoint: '/oroshi/products/:id/material_cost/:shipping_receptacle_id/:item_quantity/:receptacle_quantity/:freight_quantity'
    const productId = this.productSelectTarget.value;
    const shippingReceptacleId = this.shippingReceptacleSelectTarget.value;
    const url = `/oroshi/products/${productId}/material_cost/${shippingReceptacleId}/${itemQuantity}/${shippingReceptacleQuantity}/${freightQuantity}`;
    this.loading(true);
    fetch(url)
      .then(response => response.json())
      .then(data => {
        this.materialsCostInputTarget.value = (data.materials_cost + shippingReceptacleMaterialSubtotal + packagingCostSubtotal).toFixed(2);
        this.loading(false);
      })
      .catch(error => {
        console.error('Error:', error);
        this.loading(false);
      });
  }

  loading(loading) {
    if (loading) {
      this.element.insertAdjacentHTML('afterbegin', loading_overlay);
    } else {
      this.element.querySelector('.loading_overlay')?.remove();
    }
  }

  toggleOrderTemplateWarning(event) {
    // if the event target is checked then remove d-none from this.templateWarningTarget
    if (event.target.checked) {
      this.templateWarningTarget.classList.remove('d-none');
      this.salesCostsSectionTarget.classList.add('d-none');
    } else {
      this.templateWarningTarget.classList.add('d-none');
      this.salesCostsSectionTarget.classList.remove('d-none');
    }
  }
}