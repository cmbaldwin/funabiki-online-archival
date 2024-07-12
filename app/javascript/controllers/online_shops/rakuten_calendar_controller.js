import { Controller } from "@hotwired/stimulus";

import moment from 'moment';
import FullCalendar from 'fullcalendar';

export default class extends Controller {
  static calendar;
  static targets = ['calendar'];

  connect() {
    this.calendarTarget.innerHTML = ''; // clear calendar
    const controllerInstance = this;
    this.calendar = new FullCalendar.Calendar(this.calendarTarget, {
      ...controllerInstance.settings(controllerInstance),
      events: '/rakuten_orders.json',
      loading: function (loading) { controllerInstance.onLoading(loading) },
      eventClick: function (info) { controllerInstance.calendarClick(info) },
      dateClick: function (info) { controllerInstance.calendarClick(info) },
    });
    this.calendar.render();
  };

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
      customButtons: {},
      selectable: false,
    }
  }

  onLoading(loading) {
    if (loading) {
      this.calendarTarget.insertAdjacentHTML('afterbegin', loading_overlay);
    } else {
      document.querySelector('.loading_overlay')?.remove();
    }
  }

  calendarClick(info) {
    const dateStr = (info?.event) ? info.event.start : info.date;
    const date = encodeURI(moment(dateStr).format('YYYY-MM-DD'))
    const url = `/fetch_rakuten_orders_list/${date}`;
    Turbo.visit(url, { frame: 'daily_orders' });
  }

  disconnect() {
    this.calendar.destroy();
  }

}
