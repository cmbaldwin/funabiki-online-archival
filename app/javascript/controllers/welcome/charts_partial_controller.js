import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  connect() {
  }

  update(event) {
    const element = event.target
    const url = element.href
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