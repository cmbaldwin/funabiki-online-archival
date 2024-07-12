import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  connect() {
    const controllerInstance = this;
    tippy(this.element.querySelector('.tippy-target'), {
      content: controllerInstance.tippyLoadingSpinner(),
      allowHTML: true,
      arrow: false,
      offset: [20, -5],
      animateFill: true,
      interactive: true,
      placement: 'bottom',
      appendTo: document.body,
      theme: 'light-border',
      maxWidth: 350,
      trigger: 'click',
      onTrigger(instance, _event) {
        // check to see if contents first div is .spin-container, if not then return
        const spinContainer = instance.popper.querySelector('.spin-container');
        if (!spinContainer) return;

        // Fetch the message contents
        controllerInstance.fetchMessageContents(instance);
      },
    })
    this.ensureNoMessagesText();
  }

  ensureNoMessagesText() {
    // Check if there are no more messages, if not then add the no messages text
    const messageText = document.querySelector('#no-messages-text');
    if (messageText) messageText.remove();
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

  fetchMessageContents(instance) {
    const CSRFtoken = document.querySelector('meta[name="csrf-token"]').content;
    const url = `/message/${this.element.dataset.messageId}`;
    fetch(url, {
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': CSRFtoken
      }
    })
      .then(response => {
        const text = response.text();
        // console.log(text); // for debugging
        return text;
      })
      .then(body => {
        instance.setContent(body);
      })
      .catch((error) => {
        instance._error = error;
        instance.setContent(`エラー： ${error}`);
      })
  }

  disconnect() {
  }
}