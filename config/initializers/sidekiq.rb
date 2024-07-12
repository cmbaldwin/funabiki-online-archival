# config/initializers/sidekiq.rb

# Perform Sidekiq jobs immediately in development,
# so you don't have to run a separate process.
# You'll also benefit from code reloading.
if Rails.env.development? || Rails.env.test?
  require 'sidekiq/testing'
  Sidekiq::Testing.inline!
end

Sidekiq.strict_args!(false)
