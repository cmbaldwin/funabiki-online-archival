import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['orderModal', 'navbar', 'menuButton', 'orderFilterForm'];

  connect() {
    this.adjustNavbarForScreenSize();
    window.addEventListener('resize', () => this.adjustNavbarForScreenSize());

    this.orderModalTarget.addEventListener('hidden.bs.modal', () => {
      const turboFrame = this.orderModalTarget.querySelector('#order_modal_content .modal-body');
      if (turboFrame) {
        turboFrame.innerHTML = `
          <div class="d-flex justify-content-center">
            <div class="spinner-border" role="status">
              <span class="visually-hidden">Loading...</span>
            </div>
          </div>
        `
      };
    });
  }

  disconnect() {
    window.removeEventListener('resize', () => this.adjustNavbarForScreenSize());
  }

  adjustNavbarForScreenSize() {
    // Bootstrap's medium breakpoint is 768px
    const mediumBreakpoint = 768;
    const screenWidth = window.innerWidth;

    if (screenWidth <= mediumBreakpoint) {
      // Collapse the navbar for medium or smaller screens
      this.navbarTarget.classList.remove('show');
      this.menuButtonTarget.classList.remove('d-none');
    } else {
      // Expand the navbar for larger screens
      this.navbarTarget.classList.add('show');
      this.menuButtonTarget.classList.add('d-none');
    }
  }

  toggleActiveLink(event) {
    // if event element has a dat-turbo-frame target, fill that frame with a loading spinner before proceeding
    const turboFrame = event.target.dataset.turboFrame;
    if (turboFrame) {
      const frame = document.querySelector(`turbo-frame#${turboFrame}`);
      frame.innerHTML = `
        <div class="d-flex justify-content-center">
          <div class="spinner-border spinner-border-sm" role="status">
            <span class="visually-hidden">Loading...</span>
          </div>
        </div>
      `
    }
    // find closest .nav
    const nav = event.target.closest('.nav');
    // find all .nav-link
    const navLinks = nav.querySelectorAll('.nav-link');
    // remove active class from all .nav-link
    navLinks.forEach((link) => {
      link.classList.remove('active');
    });
    // add active class to clicked link
    event.target.closest('.nav-link').classList.add('active');
  }

  showModal() {
    const modal = bootstrap.Modal.getOrCreateInstance(this.orderModalTarget);
    modal.show();
  }

  orderModalFormSubmit(event) {
    // submit the form referenced by the event target, via fetch
    const form = event.target;
    const modal = bootstrap.Modal.getOrCreateInstance(this.orderModalTarget);
    const url = form.action;
    const method = form.method;
    const refreshTarget = form.dataset.refreshTarget
    const formData = new FormData(form);
    fetch(url, {
      method: method,
      body: formData
    })
      .then(response => {
        if (response.ok) {
          modal.hide();
          const frame = document.querySelector(`turbo-frame#${refreshTarget}`);
          frame.reload();
        } else {
          return response.text();
        }
      })
      .then(html => {
        if (html) {
          this.element.querySelector('#order_modal_content').innerHTML = html;
        }
      });
  }

  inventoryUpdate(event) {
    // even target is form, event is on submit
    const form = event.target;
    const submitButton = form.querySelector('.btn');
    submitButton.classList.remove('btn-primary');
    submitButton.classList.add('btn-yellow');
    submitButton.value = '更新中...';
    const refreshTarget = form.dataset.refreshTarget;
    refreshTarget && document.querySelector(`turbo-frame#${refreshTarget}`).reload();
  }

  resetOrderFilters(event) {
    event.preventDefault();
    this.orderFilterFormTarget.querySelectorAll('select').forEach(select => {
      select.value = ""; // Reset select
    });
  }
}