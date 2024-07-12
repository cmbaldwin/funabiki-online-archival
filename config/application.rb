require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Dev evniornment ENV file
if defined?(Dotenv)
  require 'dotenv-rails'
  Dotenv::Rails.load
end

module FunabikiOnline
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Japanese translations (incomplete b/c of time restraints)
    config.i18n.load_path += Dir[Rails.root.join('locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :ja
    config.i18n.available_locales = %i[ja]
    config.time_zone = 'Osaka'
    config.beginning_of_week = :sunday

    # Load Libraries
    config.autoload_paths += [Rails.root.join('lib'), Rails.root.join('lib/printables')]
    config.eager_load_paths += [Rails.root.join('lib'), Rails.root.join('lib/printables')]

    # Set active job adapter to sidekiq (using redis)
    config.active_job.queue_adapter = :sidekiq

    # https://discuss.rubyonrails.org/t/cve-2022-32224-possible-rce-escalation-bug-with-serialized-columns-in-active-record/81017
    config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time, DateTime,
                                                          ActiveSupport::HashWithIndifferentAccess,
                                                          HashWithIndifferentAccess, BigDecimal,
                                                          ActionController::Parameters,
                                                          ActiveSupport::TimeWithZone]
    config.active_record.use_yaml_unsafe_load = true
  end
end
