# Pin npm packages by running ./bin/importmap

# Application, hotwire, turbo, stimulus
pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers', to: 'controllers'

# Channels/ActionCable
pin '@rails/actioncable', to: 'actioncable.esm.js'
pin_all_from 'app/javascript/channels', under: 'channels'

# ActiveStorage
pin '@rails/activestorage', to: 'activestorage.esm.js'

# Bootstrap
pin 'bootstrap', to: 'bootstrap.min.js', preload: true
pin '@popperjs/core', to: 'popper.js', preload: true

# Shuffle
pin 'shufflejs', to: 'https://unpkg.com/shufflejs@6.1.0'
pin 'draggable', to: 'https://cdn.jsdelivr.net/npm/@shopify/draggable/build/esm/index.mjs'
pin 'draggable-plugins', to: 'https://cdn.jsdelivr.net/npm/@shopify/draggable/build/esm/Plugins/index.mjs'
pin 'muuri', to: 'https://cdn.jsdelivr.net/npm/muuri@0.9.5/dist/muuri.min.js'

# Tippy.js
pin 'tippy.js', to: 'https://unpkg.com/tippy.js@6.3.7/dist/tippy-bundle.umd.min.js'

# Chartkick
pin 'chartkick', to: 'chartkick.js'
pin 'Chart.bundle', to: 'Chart.bundle.js'

# FullCalendar
pin 'fullcalendar' # @6.1.10 vendored (copy and paste with `export default FullCalendar;` at end, also copied and pasted Bootstrap5 module to end)
pin 'moment' # @2.29.4 vendored (copy and paste)

# Flatpickr
pin 'flatpickr', to: 'https://ga.jspm.io/npm:flatpickr@4.6.13/dist/esm/index.js'
pin 'flatpickr/dist/l10n/ja', to: 'https://ga.jspm.io/npm:flatpickr@4.6.13/dist/l10n/ja.js'
