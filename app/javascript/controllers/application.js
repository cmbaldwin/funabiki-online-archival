import { Application } from "@hotwired/stimulus";

const application = Application.start();

// Configure Stimulus development experience
// application.debug = true;
window.Stimulus = application;

// Window overlay for loading calendar pages
window.loading_overlay = `
<div class="loading_overlay rounded">
  <div class="spinner-border text-primary position-absolute top-50 start-50" role="status">
    <span class="visually-hidden">読み込み中...</span>
  </div>
</div>
`;

// Modify inputs on Oyster Supply page so that only numbers can be entered with a single decimal, and toFixed(1) is applied on blur
window.integerInput = function (controllerInstance, teardown = false) {
  function ensureZeroWithoutLeadingZero(value) {
    if (value == '') {
      return '0';
    }
    if (value[0] == '0' && value.length > 1) {
      return value.slice(1);
    }
    return value;
  }
  controllerInstance.element.querySelectorAll('input').forEach(input => {
    if (!teardown) {
      // return if classList includes other_name or other_location
      if (input.classList.contains('other_name') || input.classList.contains('other_location')) { return };

      // on focus, select all text inside and ensure there is a zero, but not a leading zero
      input.addEventListener('focus', function () {
        this.value = ensureZeroWithoutLeadingZero(this.value);
        this.select();
      });
      // on blur, ensure there is a zero, but not a leading zero
      input.addEventListener('blur', function () {
        // if the value has a decimal use (value).toFixed(1), otherwise no change
        const decimal = this.value.indexOf('.');
        (decimal > -1) ? this.value = parseFloat(ensureZeroWithoutLeadingZero(this.value)).toFixed(1) : null;
        this.value = ensureZeroWithoutLeadingZero(this.value);
      });
      input.addEventListener('change', function () {
        this.value = ensureZeroWithoutLeadingZero(this.value);
        controllerInstance.calculate();
      });
    } else {
      input.removeEventListener('focus', function () {
        this.value = ensureZeroWithoutLeadingZero(this.value);
        this.select();
      });
      input.removeEventListener('blur', function () {
        const decimal = this.value.indexOf('.');
        (decimal > -1) ? this.value = parseFloat(ensureZeroWithoutLeadingZero(this.value)).toFixed(1) : null;
        this.value = ensureZeroWithoutLeadingZero(this.value);
      });
      input.removeEventListener('change', function () {
        this.value = ensureZeroWithoutLeadingZero(this.value);
        controllerInstance.calculate();
      });
    }
  });
};
export { application };
