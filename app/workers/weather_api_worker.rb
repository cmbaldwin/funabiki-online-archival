class WeatherApiWorker
  include Sidekiq::Worker

  def perform
    WeatherAPI.new.set_weather_data
  end
end
