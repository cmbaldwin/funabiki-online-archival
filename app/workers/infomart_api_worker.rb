class InfomartApiWorker
  include Sidekiq::Worker

  def perform
    InfomartAPI.new.acquire_new_data
  end
end
