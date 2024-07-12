require 'selenium-webdriver'
require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  Capybara.register_driver :selenium_chrome do |app|
    options = Selenium::WebDriver::Options.chrome

    # Enable browser logging
    options.add_argument('enable-logging')
    options.add_argument('v=3')
    options.add_argument('vmodule=console=3')

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  Capybara.javascript_driver = :selenium_chrome
  Capybara.default_max_wait_time = 5

  driven_by :selenium_chrome, using: :chrome # :headless_chrome #
  Capybara.server = :puma, { Silent: true }

  # Selenium::WebDriver.logger.ignore(:browser_options)

  # Great cheatsheet here: https://gist.github.com/zhengjia/428105
  # eg. puts find('#some-element-id').native.attribute("innerHTML")
end
