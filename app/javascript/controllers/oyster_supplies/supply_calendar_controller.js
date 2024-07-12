import { Controller } from "@hotwired/stimulus";

import moment from 'moment';
import FullCalendar from 'fullcalendar';

export default class extends Controller {
  static calendar;
  static targets = ['calendar', 'supplyModal'];

  connect() {
    this.calendarTarget.innerHTML = ''; // clear calendar
    const controllerInstance = this;
    this.calendar = new FullCalendar.Calendar(this.calendarTarget, {
      ...controllerInstance.settings(controllerInstance),
      events: '/oyster_supplies.json?place=' + this.calendarTarget.dataset.place,
      eventDidMount: function (info) { controllerInstance.onEventDidMount(info) },
      eventClick: function (info) { controllerInstance.onEventClick(info) },
      selectable: true,
      dateClick: function (info) { controllerInstance.onDateClick(info) },
      select: function (info) { controllerInstance.onSelect(info) },
      unselect: function (info) { controllerInstance.onDeselect(info) },
      loading: function (loading) { controllerInstance.onLoading(loading) }
    });
    this.calendar.render();
    this.supplyModalTarget.addEventListener('hidden.bs.modal', () => {
      // refresh current calendar data
      this.calendar.refetchEvents();
    })
  }

  disconnect() {
    this.calendar.destroy();
    this.calendarTarget.innerHTML = '';
  }

  settings(controllerInstance) {
    return {
      locale: 'ja',
      contentHeight: 800,
      aspectRatio: 1.35,
      themeSystem: 'bootstrap5',
      headerToolbar: {
        left: 'prevYear,prev,next,nextYear,reload shikiriList shikiriNew tankaEntry analysis',
        center: '',
        right: 'title'
      },
      customButtons: this.customButtons(controllerInstance),
    }
  }

  customButtons(controllerInstance) {
    return {
      reload: {
        icon: 'arrow-clockwise',
        click: function () {
          controllerInstance.refreshCalendarPage();
        },
        hint: 'カレンダーを更新します。'
      },
      shikiriList: {
        text: '仕切り表',
        click: function () {
          Turbo.visit('/oyster_invoices', { frame: 'app ', action: 'advance' })
        },
        hint: 'すべとの仕切りを表示します。'
      },
      shikiriNew: {
        text: '仕切り作成',
        click: function () {
          controllerInstance.requestAction(controllerInstance, 'supply_invoice_actions');
        },
        hint: '現在選択してある日付範囲で新しい仕切りを作成します。'
      },
      tankaEntry: {
        text: '単価入力',
        click: function () {
          controllerInstance.requestAction(controllerInstance, 'supply_price_actions');
        },
        hint: '現在選択してある日付範囲で各産地の生産者の単価を入力します。'
      },
      analysis: {
        text: 'データ分析',
        click: function () {
          controllerInstance.requestAction(controllerInstance, 'supply_stats_partial');
        },
        hint: '現在選択してある日付範囲データを分析します。'
      }
    }
  }

  requestAction = (controllerInstance, path) => {
    const start_date = document.getElementById('supply_calendar').dataset.startDate;
    const end_date = document.getElementById('supply_calendar').dataset.endDate;
    fetch(`/oyster_supplies/${path}/${start_date}/${end_date}`,
      {
        method: "GET",
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Content-Type': 'application/json',
          "X-Requested-With": "XMLHttpRequest"
        },
        credentials: "same-origin",
      })
      .then(response => {
        const text = response.text();
        // console.log(text); // for debugging
        return text;
      })
      .then(body => Turbo.renderStreamMessage(body))
    controllerInstance.showModal();
  }

  showModal() {
    const modal = bootstrap.Modal.getOrCreateInstance(this.supplyModalTarget, {
      keyboard: false
    });
    modal.show();
  }

  onEventDidMount(info) {
    if (info.el.classList.contains('supply_event')) {
      tippy('.tippy_' + info.event.extendedProps.supply_id, {
        onShow(instance) {
          instance.setContent(info.event.extendedProps.description)
        },
        allowHTML: true,
        animation: 'scale',
        duration: [100, 0],
        touch: true,
        theme: 'supply_cal',
        touch: 'hold'
      });
    }
  }

  onEventClick(info) {
    //disable default
    info.jsEvent.preventDefault();
    switch (info.event.extendedProps.type) {
      case 'invoice':
        fetch(`/oyster_supplies/fetch_invoice/${info.event.id}`,
          {
            method: "GET",
            headers: {
              'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
              'Content-Type': 'application/json',
              "X-Requested-With": "XMLHttpRequest"
            },
            credentials: "same-origin",
          })
          .then(response => response.text())
          .then(body => { Turbo.renderStreamMessage(body) })
        this.showModal();
        break;
      default:
        this.onDateClick(info);
        break;
    }
  }

  onDateClick(info) {
    this.onLoading(true);
    const appendAreaButton = document.querySelector('.fc-appendArea-button');
    if (appendAreaButton) {
      appendAreaButton.remove();
    }
    const href = info?.el?.href;
    const new_date = moment(info.date).format('YYYY-MM-DD');
    const url = href ? href : `/oyster_supplies/new_by/${encodeURI(new_date)}`;
    Turbo.visit(url, { frame: 'app', action: 'advance' })
    // manually confirm that the window url is the same as the url we want to visit
    // if not, then just change the url manually
    if (window.location.href !== url) {
      window.history.pushState({}, '', url);
    }
  }

  onSelect(info) {
    const start_date = info.startStr;
    const end_date = info.endStr;
    const difference = moment(end_date).diff(moment(start_date), "hours");
    if (difference > 24) {
      const display_end = moment(end_date).subtract(1, 'days').format('YYYY-MM-DD');
      document.getElementById('supply_action_date_title').innerHTML = '　(' + start_date + ' ~ ' + display_end + ')';
      this.calendarTarget.dataset.startDate = start_date;
      this.calendarTarget.dataset.endDate = end_date;
      this.enableSelectionButtons();
    }
  }

  onDeselect(info) {
    const button_list = ['shikiriList', 'fc-shikiriNew-button', 'fc-tankaEntry-button', 'fc-analysis-button'];
    const targetClass = info.jsEvent.target.classList;
    // if target class list includes any item from this list do nothing
    if (button_list.some((button) => targetClass.contains(button))) {
      return;
    } else {
      delete this.calendarTarget.dataset.startDate;
      delete this.calendarTarget.dataset.endDate;
      this.disableSelectionButtons();
    }
  }

  onLoading(loading) {
    this.disableSelectionButtons();
    if (loading) {
      document.getElementById('supply_calendar').insertAdjacentHTML('afterbegin', loading_overlay);
    } else {
      document.querySelector('.loading_overlay')?.remove();
    }
  }

  disableSelectionButtons() {
    ['fc-shikiriNew-button', 'fc-tankaEntry-button', 'fc-analysis-button'].forEach((button) => {
      button = document.querySelector('.' + button);
      if (button) {
        button.disabled = true;
      }
    });
  }

  enableSelectionButtons() {
    ['fc-shikiriNew-button', 'fc-tankaEntry-button', 'fc-analysis-button'].forEach((button) => {
      button = document.querySelector('.' + button);
      if (button) {
        button.disabled = false;
      }
    });
  }

  refreshCalendarPage() {
    this.calendar.refetchEvents();
    const modalBackdrop = document.querySelector('.modal-backdrop');
    if (modalBackdrop) {
      modalBackdrop.remove();
    }
  }

}
