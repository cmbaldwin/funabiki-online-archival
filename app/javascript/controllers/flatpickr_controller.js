import { Controller } from "@hotwired/stimulus";
import flatpickr from "flatpickr";
import { Japanese } from "flatpickr/dist/l10n/ja";

export default class extends Controller {
  static instance;
  static targets = [];

  connect() {
    const includeTime = this.element.dataset.includeTime === 'true'
    const supplyLink = this.element.dataset.supplyLink === 'true'
    const initDateTime = this.element.dataset.initDateTime
    const parsedInitDate = initDateTime ? new Date(initDateTime) : null
    const config = {
      locale: Japanese,
      enableTime: includeTime,
      dateFormat: `Y年m月d日${includeTime ? ' H:i' : ''}`,
      monthSelectorType: 'static',
      defaultDate: parsedInitDate,
      onReady: function (_selectedDates, dateStr, _instance) {
        const date = dateStr.replace(/年|月/g, '-').replace(/日/g, '');
        // set the data-date attribute
        this.element.dataset.date = date;
      }.bind(this), // bind this to the function scope
      onChange: function (_selectedDates, dateStr, instance) {
        // convert a date like 2021年01月01日 to 2021-01-01
        const date = dateStr.replace(/年|月/g, '-').replace(/日/g, '');
        // set the data-date attribute
        this.element.dataset.date = date;

        if (supplyLink) {
          // Warn that unsaved changes will be lost with confirm()
          // If user clicks OK, open new supply page
          if (confirm('変更を保存せずに牡蠣供給入力表を開けます。よろしいですか？')) {
            window.open(`/oyster_supplies/new_by/${encodeURI(date)}`, '_top');
          } else {
            // If user clicks cancel, reset the date to the previous one
            instance.setDate(parsedInitDate);
          }
        }
      }.bind(this) // bind this to the function scope
    }
    this.instance = flatpickr(this.element, config);
  }

  disconnect() {
    this.instance.destroy();
  }
}