import { Controller } from "@hotwired/stimulus";

import moment from 'moment';
import FullCalendar from 'fullcalendar';

export default class extends Controller {
  static calendar;
  static targets = ['calendar'];

  connect() {
    this.calendarTarget.innerHTML = ''; // clear calendar
    this.orderModal = document.getElementById('orderModal');
    const controllerInstance = this;
    this.calendar = new FullCalendar.Calendar(this.calendarTarget, {
      ...controllerInstance.settings(controllerInstance),
      events: '/oroshi/orders/calendar/orders',
      eventClick: function (info) { controllerInstance.onEventClick(info) },
      selectable: false,
      dateClick: function (info) { controllerInstance.onDateClick(info) },
      loading: function (loading) { controllerInstance.onLoading(loading) }
    });
    this.calendar.render();
    this.orderModal.addEventListener('shown.bs.modal', (_event) => {
      this.calendar.updateSize();
    });
  }

  settings(_controllerInstance) {
    return {
      locale: 'ja',
      themeSystem: 'bootstrap5',
      headerToolbar: {
        left: 'prevYear,prev,next,nextYear',
        center: '',
        right: 'title'
      }
    }
  }

  onEventClick(info) {
    this.closeModal();
    window.location.href = info.event.url;
  }

  onDateClick(info) {
    this.closeModal();
    let url = new URL(window.location.origin);
    url.pathname = `/oroshi/orders/${info.dateStr}`;
    window.location.href = url.href;
  }

  closeModal() {
    const dismissButton = this.orderModal.querySelector('[data-bs-dismiss="modal"]');
    if (dismissButton) {
      dismissButton.click();
    }
  }

  onLoading(loading) {
    if (loading) {
      document.getElementById('order_calendar').insertAdjacentHTML('afterbegin', loading_overlay);
    } else {
      document.querySelector('.loading_overlay')?.remove();
    }
  }

  refreshCalendarPage() {
    this.calendar.refetchEvents();
    const modalBackdrop = document.querySelector('.modal-backdrop');
    if (modalBackdrop) {
      modalBackdrop.remove();
    }
  }

}
