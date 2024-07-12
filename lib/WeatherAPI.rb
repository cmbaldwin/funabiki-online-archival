class WeatherAPI
  require 'uri'
  require 'net/http'
  require 'openssl'

  def initialize
    @url = URI("https://api.tomorrow.io/v4/timelines?apikey=#{ENV['TOMORROWIO']}")
  end

  def get_standard_response
    http = Net::HTTP.new(@url.host, @url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(@url)
    request['Accept'] = 'application/json'
    request['Content-Type'] = 'application/json'

    request.body = {
      "units": 'metric',
      "timesteps":
        %w[1h 1d],
      "location": {
        "type": 'Point',
        "coordinates": [
          134.37865018844604,
          34.733748064862645
        ]
      },
      "timezone": 'Japan',
      "fields": %w[
        precipitationIntensity
        precipitationType
        precipitationProbability
        windSpeed
        windGust
        windDirection
        humidity
        temperature
        temperatureApparent
        cloudCover
        cloudBase
        cloudCeiling
        moonPhase
        weatherCode
        visibility
        uvHealthConcern
        rainAccumulation
        snowAccumulation
        iceAccumulation
      ]
    }.to_json

    response = http.request(request)
    response.read_body
  end

  def set_weather_data
    initial_response = get_standard_response
    parsed_response = JSON.parse(initial_response)['data']
    if parsed_response
      stat = Stat.get_most_recent
      stat.weather.nil? ? (stat.weather = parsed_response) : (stat.weather = stat.weather.deep_merge(parsed_response))
      stat.save
    else
      p 'Error'
      ap initial_response
    end
  end

  def get_recent_data
    stat = Stat.where.not(weather: nil).order(:date).last
    stat.weather['timelines'].first if stat
  end

  def parse_today
    recent = get_recent_data
    data = {}
    if recent
      get_recent_data['intervals'].each do |interval|
        date = Date.parse(interval['startTime'])
        hour = DateTime.parse(interval['startTime']).hour
        data[date] = {} if data[date].nil?
        data[date][hour] = interval['values']
      end
    end
    data
  end
end
