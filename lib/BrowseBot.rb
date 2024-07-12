# frozen_string_literal: true

require 'httparty'
require 'nokogiri'

# Browse Bot - Simple tool for scraping to a Rails cache or Setting model
class BrowseBot
  include HTTParty

  attr_reader :data

  def initialize
    @data = Rails.cache.fetch('BrowseBotAPI_data')
    @data ||= {} unless @data.is_a?(Hash)
  end

  def test_setup
    # create a list of random days out of the year in an array, as dates
    # find 50 rnadom numbers between 1 and 365, and make them dates
    dates = []
    60.times do
      dates << (Date.today.beginning_of_year + rand(1..365).days)
    end
    dates.uniq.sort!
  end

  def ichiba_holiday_events(range)
    return test_setup if Rails.env.test?

    first_year = range.first.year
    last_year = range.last.year
    ichiba_holidays = ichiba_holidays(first_year)
    ichiba_holidays.concat(ichiba_holidays(last_year)) if first_year != last_year
    ichiba_holidays
  end

  def ichiba_holidays(year)
    holidays = @data.dig(:holidays, year)
    return holidays if holidays

    @data[:holidays] = {} unless @data[:holidays].is_a?(Hash)
    @data[:holidays][year] = get_ichiba_calendar(year)
    Rails.cache.write('BrowseBotAPI_data', @data)
    @data.dig(:holidays, year)
  end

  def get_ichiba_calendar(year)
    return unless year.is_a?(Integer)

    html = get_year_html(year)
    dates = []
    html.css('.calendarBox').first.css('table').each do |m|
      m.css('td.holiday').each do |hd|
        dates << Date.parse("#{year}-#{m.attribute('id').to_s[/(?<=m01)\d./]}-#{hd.text}")
      end
    end
    dates
  end

  def get_year_html(year)
    url = "https://www.shijou.metro.tokyo.lg.jp/calendar/#{year}/"
    response = HTTParty.get(url)
    Nokogiri::HTML(response.body)
  end
end
