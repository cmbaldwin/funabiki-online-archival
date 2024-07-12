Rails.application.routes.default_url_options[:host] = ENV.fetch('LOCAL_IP', 'localhost')
Rails.application.routes.default_url_options[:port] = ENV.fetch('PORT', '3000')
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :google_active_storage

  # Mailer setup (SendGrid)
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default charset: 'utf-8'
  config.action_mailer.smtp_settings = {
    user_name: ENV.fetch('SENDGRID_TWILIO_API_USERNAME', nil),
    password: ENV.fetch('SENDGRID_TWILIO_API_PASSWORD', nil),
    domain: 'funabiki.info',
    address: 'smtp.sendgrid.net',
    port: 587,
    authentication: :plain,
    enable_starttls_auto: true
  }

  # Added as per Devise configuration instructions (8-8-2018 10:47am) (kept: 4-5-2019)
  config.action_mailer.default_url_options = { host: '133.208.230.195', port: 3000 }

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true
  # config.log_level = :info

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # BULLET - N+1 queries
  config.after_initialize do
    Bullet.enable = true
    # Bullet.sentry = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    # # Bullet.xmpp = { :account => 'bullets_account@jabber.org',
    # #                 :password => 'bullets_password_for_jabber',
    # #                 :receiver => 'your_account@jabber.org',
    # #                 :show_online_status => true }
    Bullet.rails_logger = true
    # Bullet.honeybadger = true
    # Bullet.bugsnag = true
    # Bullet.appsignal = true
    # Bullet.airbrake = true
    # Bullet.rollbar = true
    # Bullet.add_footer = true
    # Bullet.skip_html_injection = false
    # Bullet.stacktrace_includes = %w[your_gem your_middleware]
    # Bullet.stacktrace_excludes = ['their_gem', 'their_middleware', ['my_file.rb', 'my_method'], ['my_file.rb', 16..20]]
    # Bullet.slack = { webhook_url: 'http://some.slack.url', channel: '#default', username: 'notifier' }
  end
end
