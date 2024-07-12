# Rakuten - Interface for Rakuten backoffice
module Rakuten
  class Api
    include HTTParty
    include Rakuten::Orders
    include Rakuten::Automation
    include Rakuten::Settings
    include Rakuten::Items
    base_uri 'https://api.rms.rakuten.co.jp/es/2.0/'

    def initialize
      @options = { headers: { 'Authorization' => authorization } }

      @options[:headers]['Content-Type'] = 'application/json; charset=utf-8'
    end

    def authorization
      service_secret = get_setting('serviceSecret') || ENV.fetch('RAKUTEN_SERVICE_SECRET', nil)
      license_key = get_setting('licenseKey') || ENV.fetch('RAKUTEN_LICENSE_KEY', nil)
      key = Base64.encode64("#{service_secret}:#{license_key}").gsub("\n", '')
      "ESA #{key}"
    end

    def get_setting(setting_name)
      settings = Setting.find_or_initialize_by(name: 'rakuten_processing_settings')
      settings&.settings&.dig(setting_name)
    end

    # aspects of the API we utilize only use POST requests
    def post(path, options = {})
      self.class.post(path, options.merge(@options))
    end

    def get(path, options = {})
      self.class.get(path, options.merge({ headers: { 'Authorization' => "ESA #{ENV.fetch('RAKUTEN_API')}" } }))
    end

    def jsonify_date(date)
      date.strftime('%Y-%m-%dT%H:%M:%S') + '+0900'
    end
  end
end
