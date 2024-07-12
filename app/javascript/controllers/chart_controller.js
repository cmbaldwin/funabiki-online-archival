import { Controller } from "@hotwired/stimulus";

// Chartkick
import "chartkick"
import "Chart.bundle"

export default class extends Controller {
  static targets = [];

  connect() {
    // Find the script inside this element div and run it
    const chart = this.element.querySelector("script")
    chart ? eval(chart.innerHTML) : null
  }
}