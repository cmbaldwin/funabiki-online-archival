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
      events: 'supplies.json',
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
      // set interior html to .modal-body to clear out any previous content
      this.supplyModalTarget.querySelector('.modal-body').innerHTML = `
        <div class="w-100 text-center">
          <div class="spinner-border spinner-border-sm" role="status">
            <span class="visually-hidden">読み込み中...</span>
          </div>
        </div>`;

    })
  }

  disconnect() {
    this.calendar.destroy();
    this.calendarTarget.innerHTML = '';
  }

  settings(controllerInstance) {
    return {
      locale: 'ja',
      aspectRatio: 1.78, // 16:9
      themeSystem: 'bootstrap5',
      headerToolbar: {
        left: 'prevYear,prev,next,nextYear,reload shikiriList shikiriNew tankaEntry',
        center: '',
        right: 'title'
      },
      customButtons: this.customButtons(controllerInstance),
      progressiveEventRendering: true,
      dayMaxEventRows: true, // for all non-TimeGrid views
      moreLinkClassNames: 'text-center w-100',
      eventOrder: ['order', 'title'],
      moreLinkContent: function (args) {
        return `${args.num}供給件を表示`;
      }
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
          Turbo.visit('/oroshi/invoices', { frame: 'app ', action: 'advance' })
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
      // analysis: {
      //   text: 'データ分析',
      //   click: function () {
      //     controllerInstance.requestAction(controllerInstance, 'supply_stats_partial');
      //   },
      //   hint: '現在選択してある日付範囲データを分析します。'
      // }
    }
  }

  requestAction = (controllerInstance, path) => {
    const startDate = new Date(document.getElementById('supply_calendar').dataset.startDate);
    const endDate = new Date(document.getElementById('supply_calendar').dataset.endDate);

    // Create an array of dates
    const supplyDates = [];
    for (let date = startDate; date <= endDate; date.setDate(date.getDate() + 1)) {
      supplyDates.push(date.toISOString().split('T')[0]);
    }

    // Convert the array of dates to a query string
    const queryString = supplyDates.map(date => `supply_dates[]=${date}`).join('&');

    fetch(`supply_dates/${path}?${queryString}`,
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
      .then(body => Turbo.renderStreamMessage(body))

    controllerInstance.showModal();
  }

  showModal() {
    const modal = bootstrap.Modal.getOrCreateInstance(this.supplyModalTarget, {
      keyboard: false
    });
    modal.show();
  }

  onEventClick(info) {
    //disable default
    info.jsEvent.preventDefault();
    switch (info.event.extendedProps.type) {
      case 'invoice':
        fetch(`/oroshi/invoices/${info.event.id}/edit`,
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
    if (info?.event?.url) return Turbo.visit(info.event.url, { frame: 'app', action: 'advance' })

    const new_date = moment(info.date).format('YYYY-MM-DD');
    const url = `/oroshi/supply_dates/${encodeURI(new_date)}`;
    Turbo.visit(url, { frame: 'app', action: 'advance' })
  }

  onSelect(info) {
    const start_date = info.startStr;
    let end_date = moment(info.endStr).subtract(1, 'days').format('YYYY-MM-DD');
    const difference = moment(end_date).diff(moment(start_date), "hours");
    if (difference > 24) {
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
