import { Controller } from "@hotwired/stimulus";

//import moment from 'moment';
import FullCalendar from 'fullcalendar';

export default class extends Controller {
  static targets = ['calendar'];

  connect() {
    this.calendarTarget.innerHTML = ''; // clear calendar
    const controllerInstance = this;
    const calendar = new FullCalendar.Calendar(this.calendarTarget, {
      ...controllerInstance.settings(controllerInstance),
      selectable: false,
      events: '/profits.json',
      eventClick: function (info) {
        const location = `${info.event.url}`;
        Turbo.visit(location, { frame: 'app', action: 'replace' });
        const backdrop = document.querySelector('.modal-backdrop');
        if (backdrop) backdrop.remove();
      },
      loading: function (loading) { controllerInstance.onLoading(loading) }
    });
    calendar.render();
    var myModalEl = document.getElementById('ProfitModal')
    if (myModalEl) {
      myModalEl.addEventListener('shown.bs.modal', function (_event) {
        calendar.destroy();
        calendar.refetchEvents();
        calendar.render();
        calendar.updateSize()
      })
    };
  }

  settings(_controllerInstance) {
    return {
      locale: 'ja',
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
      document.getElementById('profit_calendar').insertAdjacentHTML('afterbegin', loading_overlay);
    } else {
      document.querySelector('.loading_overlay')?.remove();
    }
  }

}
