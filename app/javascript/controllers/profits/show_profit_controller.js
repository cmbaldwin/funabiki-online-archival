import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  connect() {
    this.initScrollspy();
  }

  initScrollspy() {
    const scrollspy = new bootstrap.ScrollSpy(document.body, {
      target: "#profit_sidebar",
      offset: 200,
    });
  }

}
