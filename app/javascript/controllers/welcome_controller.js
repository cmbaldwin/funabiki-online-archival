import { Controller } from "@hotwired/stimulus";

// Shuffle
import 'shufflejs';

export default class extends Controller {
  static targets = [];

  connect() {
    // Shuffle for frontpage
    const grid = document.getElementById("grid");
    if (grid) {
      const shuffleInstance = new Shuffle(grid, {
        itemSelector: ".shuffle-brick",
        sizer: ".shuffle-sizer",
      });
      document.addEventListener("turbo:frame-load", function (_e) {
        shuffleInstance.update();
      })
    }
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", function (_e) {
      shuffleInstance.update();
    })
  }

}
