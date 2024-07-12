import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  connect() {
    // submitform via ajax
    this.element.addEventListener('change', (_event) => {
      this.submitForm();
    });
  }

  disconnect() {
    this.submitForm();
  }

  CSRFtoken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    if (!meta) { return }

    return meta.getAttribute('content')
  }

  submitForm() {
    //submit form via ajax with the param autosave: true
    const form = this.element;
    const reload = form.dataset.reload === 'true';
    if (!form) return;

    // remove bg-* class from form if it has it
    // track if the form had a bg-* class
    for (const className of form.classList) {
      if (className.includes('bg-') && className !== 'bg-warning') {
        form.dataset.bgClass = className;
        form.classList.remove(className);
      }
    }

    // add bg-yellow to the form
    if (!form.classList.contains('bg-yellow')) {
      form.classList.add('bg-yellow');
    }

    // add the autosave param to the form data
    const formData = new FormData(form);
    formData.append("autosave", true);
    const url = form.getAttribute('action');
    const token = this.CSRFtoken();

    // fetch/patch the form data
    fetch(url, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': token
      },
      body: formData
    }).then(response => {
      // remove bg-yellow and bg-warning classes from form if they exist
      ['bg-yellow', 'bg-warning'].forEach(className => {
        if (form.classList.contains(className)) {
          form.classList.remove(className);
        }
      });

      if (response.ok) {
        // add the bg-success class to the form with a 1 second timeout
        form.classList.add('bg-success');
        // reload the closest turbo frame if reload is true
        if (reload) {
          const frame = form.closest('turbo-frame');
          frame.reload();
        } else {
          setTimeout(() => {
            form.classList.remove('bg-success');
            // add bg back to the form if it had it
            if (form.dataset.bgClass) {
              form.classList.add(form.dataset.bgClass);
            }
          }, 200);
        }
      } else {
        console.log('Update failed!');
        form.classList.add('bg-warning');
      }
    });
  }
}