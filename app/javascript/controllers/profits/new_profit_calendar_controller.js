import { Controller } from "@hotwired/stimulus";

import moment from 'moment';
import FullCalendar from 'fullcalendar';

export default class extends Controller {
  static targets = ['calendar'];

  connect() {
    this.myModalEl = document.getElementById('newProfitModal')
    this.calendarTarget.innerHTML = ''; // clear calendar
    const controllerInstance = this;
    const calendar = new FullCalendar.Calendar(this.calendarTarget, {
      ...controllerInstance.settings(controllerInstance),
      selectable: false,
      dateClick: function (info) {
        const date = encodeURI(moment(info.date).format('YYYY年MM月DD日'));
        window.location.href = `profits/new/${date}`;
        //Turbo.visit(`profits/new/${date}`, { frame: 'app', action: 'advance' });
      },
      loading: function (loading) { controllerInstance.onLoading(loading) }
    });
    calendar.render();
    if (this.myModalEl) {
      this.myModalEl.addEventListener('shown.bs.modal', function (_event) {
        calendar.destroy();
        calendar.render();
        calendar.updateSize()
      })
    };
  }

  disconnect() {
    this.myModalEl.removeEventListener('shown.bs.modal', function (event) {
      calendar.destroy();
      calendar.render();
      calendar.updateSize()
    })
  }

  settings(_controllerInstance) {
    return {
      locale: 'ja',
      contentHeight: 450,
      aspectRatio: 1,
      themeSystem: 'bootstrap5',
      headerToolbar: {
        left: 'prevYear,prev,next,nextYear',
        center: '',
        right: 'title'
      },
      customButtons: {}
    }
  }

  onLoading(loading) {
    if (loading) {
      document.getElementById('new_profit_calendar').insertAdjacentHTML('afterbegin', loading_overlay);
    } else {
      document.querySelector('.loading_overlay')?.remove();
    }
  }

}
