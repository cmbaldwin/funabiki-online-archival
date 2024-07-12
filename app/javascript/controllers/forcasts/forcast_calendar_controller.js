import { Controller } from "@hotwired/stimulus";

import moment from 'moment';
import FullCalendar from 'fullcalendar';

export default class extends Controller {
  static targets = ['calendar'];

  connect() {
    this.calendarTarget.innerHTML = ''; // clear calendar
    const controllerInstance = this;
    const calendar = new FullCalendar.Calendar(this.calendarTarget, {
      ...controllerInstance.settings(controllerInstance),
      selectable: false,
      events: '/fetch_forcast_calendar_counts.json',
      // eventClick: function (_info) { },
      loading: function (loading) { controllerInstance.onLoading(loading, controllerInstance) },
      eventDidMount: function (info) { controllerInstance.onEventDidMount(info) },
    });
    var calendarTabEl = document.querySelector('button[data-bs-target="#nav-calendar"]');
    calendarTabEl.addEventListener('shown.bs.tab', function (_event) {
      calendar.destroy();
      calendar.render();
      calendar.updateSize();
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
      },
      customButtons: {}
    }
  }

  onLoading(loading, controllerInstance) {
    if (loading) {
      controllerInstance.calendarTarget.insertAdjacentHTML('afterbegin', loading_overlay);
    } else {
      controllerInstance.element.querySelector('.loading_overlay')?.remove();
    }
  }

  onEventDidMount(info) {
    if (info.el.classList.contains('count_event')) {
      info.el.innerHTML += info.event.extendedProps.body_text;
      tippy('.count_tippy_' + encodeURI(moment(info.event.start).format('YYYY_MM_DD')), {
        allowHTML: true,
        animation: 'scale',
        duration: [100, 0],
        theme: 'supply_cal',
        interactive: true,
        trigger: 'click',
        touch: 'hold',
        content: `
          <div class="spinner-border spinner-border-sm d-block mx-auto my-3 text-light" role="status">
            <span class="visually-hidden">読み込み中...</span>
          </div>`,
        onShow(instance) {
          // On show get tippy stat given a supply ID (as :id) and the "stat name" (as :stat) in the data from the div where the tippy is applied
          fetch('count_calendar_event_tippy/' + encodeURI(moment(info.event.start).format('YYYY_MM_DD')))
            .then(response => response.text())
            .then(result => instance.setContent(result))
            .catch((error) => {
              instance._error = error;
              instance.setContent(`エラー： ${error}`);
            })
        },
      });
    }
  }

}
