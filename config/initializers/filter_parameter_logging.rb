# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
unless Rails.env.development?
  Rails.application.config.filter_parameters += %i[
    password data oysters details items access_token authorization_code passw secret token _key crypt salt certificate otp ssn
  ]
end
