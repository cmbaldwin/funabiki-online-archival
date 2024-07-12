source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Sometimes slug size can be reduced by repo interactions:
# heroku repo:gc --app funabiki-online
# heroku repo:purge_cache --app funabiki-online
# heroku config:set BUNDLE_WITHOUT="development:test" --app funabiki-online

# Using rbenv locally https://github.com/rbenv/rbenv#installing-ruby-versions
# To get to 3.3.1 with yjit on Mac M1+: https://github.com/ruby/iconv/issues/25
ruby '3.3.3'

# Set up local .env file, require immediately
gem 'dotenv-rails', groups: %i[development test], require: 'dotenv/load'

gem 'sidekiq'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails'
gem 'rake'
gem 'sprockets-rails'

# CSS and JS
gem 'bootstrap', '~> 5'
gem 'cssbundling-rails'
gem 'importmap-rails'
gem 'rack-cache'
gem 'sassc-rails'
gem 'stimulus-rails'
gem 'turbo-rails', github: 'hotwired/turbo-rails'

# Use postgresql as the database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma'
# https://stackoverflow.com/questions/70500220/rails-7-ruby-3-1-loaderror-cannot-load-such-file-net-smtp
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false

# For Scaling with Redis and Sidekiq
# https://stackoverflow.com/questions/13770713/rails-starting-sidekiq-on-heroku
# https://github.com/mperham/sidekiq/wiki/Active+Job
gem 'hiredis'
gem 'redis', '~> 4.0.1'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# For debugging/analyzing Hash/API output, etc.
gem 'awesome_print'

# Heroku's Metrics for Ruby
gem 'barnes'

# Carmen for regions
gem 'carmen'
gem 'rails-i18n'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'listen'
  # Allow all origins for CORS in dev/test
  gem 'rack-cors'
  # Visualize associations
  gem 'rails-erd'
  # Controller Testing
  gem 'rails-controller-testing'
  # Rubocop
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  # Redis tests
  gem 'redis-namespace'
  ## Dump Seeds and reset pk squence for reproducing test databases
  gem 'seed_dump'
  # gem 'activerecord-reset-pk-sequence'
end

group :development do
  gem 'bullet'
  gem 'certified'
  gem 'derailed'
  gem 'iconv', '~> 1.0.3'
  gem 'mailcatcher' # Mailcatcher for local mail debugging
  gem 'sorbet', require: false
  gem 'sorbet-runtime', require: false
  gem 'tapioca', require: false
  gem 'watchman'
  gem 'web-console'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara'
  gem 'capybara-lockstep'
  # Factory Bot and Faker
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'ffaker'
  # Pry for debugging
  gem 'pry-byebug'
  # Rspec
  gem 'rspec-rails'
  gem 'rspec-sidekiq'
  gem 'shoulda-matchers'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'selenium-webdriver'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Add Devise for Authorization and Authentication
gem 'devise', '>= 4.7.1'

# Auto-upload setup for Google
gem 'carrierwave'
gem 'carrierwave-google-storage'
gem 'google-api-client'

# Support for Rich Text image processing
# # Auto-upload setup for Google
# # See here for how to setup credentials: https://devdojo.com/bryanborge/adding-google-cloud-credentials-to-heroku
gem 'file_validators'
gem 'google-cloud-storage', '1.37.0'
gem 'image_processing', '~> 1.2'
# gem 'imgproxy' # optional

# Easy Categories for Manual Articles
gem 'ancestry'

# Simple Form
gem 'simple_form'

# Sendgrid for confirmations, etc.
gem 'sendgrid-ruby'

## Gemfile for Rails 3+, Sinatra, and Merb
gem 'will_paginate'

## PDF reader and writer
gem 'matrix' # required for prawn
gem 'prawn', '2.4.0'
gem 'prawn-table'
gem 'ttfunk', '1.7.0'

## On the fly Hankaku / Zenkaku Conversion (http://gimite.net/gimite/rubymess/moji.html)
gem 'moji', github: 'cmbaldwin/moji'

## API/HTTP Requests
gem 'httparty'

## Charts
gem 'chartkick'
gem 'groupdate'

## Japanese Holidays (eg. calendar rendering, forcasts)
gem 'holiday_jp'

## Finding next and previous entries for models https://github.com/glebm/order_query
gem 'order_query'

## For uploading/streaming CSV/XLS data to/from the client
gem 'csv'
gem 'spreadsheet'
