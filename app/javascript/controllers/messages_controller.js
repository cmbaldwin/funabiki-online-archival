import { Controller } from "@hotwired/stimulus";
import { createConsumer } from "@rails/actioncable";

export default class extends Controller {
  static targets = ['messagesList'];

  connect() {
    const user_id = this.element.dataset.userId;
    if (!user_id || isNaN(parseInt(user_id))) return;

    this.loadIndex();
    const controllerInstance = this;
    const consumer = createConsumer();
    this.CSRFtoken = document.querySelector('meta[name="csrf-token"]').content;

    consumer.subscriptions.create({ channel: "MessagesChannel", user: user_id }, {
      connected() {
        //console.log("User with ID " + user_id + " connected to messages...");
      },

      disconnected() {
        //console.log("User with ID " + user_id + " disconnected from messages...");
      },

      received(data) {
        //console.log(data)
        if (data.action == 'remove') {
          controllerInstance.refresh();
          return;
        }
        this.render(data.id, data.action);
      },

      render(id, action) {
        const url = `/messages/${id}/${action}`;
        fetch(url, {
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'X-CSRF-Token': this.CSRFtoken
          }
        })
          .then(response => response.text())
          .then(body => { Turbo.renderStreamMessage(body) })
      },

    });
  }

  loadIndex() {
    const url = `/messages`;
    const CSRFtoken = document.querySelector('meta[name="csrf-token"]').content;
    fetch(url, {
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': this.CSRFtoken
      }
    })
      .then(response => {
        const text = response.text();
        // console.log(text); // for debugging
        return text;
      })
      .then(body => Turbo.renderStreamMessage(body))
  }

  refresh() {
    this.loadIndex();
  }
}
