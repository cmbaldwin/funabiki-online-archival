class RakutenBigRefreshWorker
  include Sidekiq::Worker

  def perform(message_id = nil)
    message = Message.find(message_id) if message_id
    client = Rakuten::Api.new
    message&.update(message: '楽天2ヶ月のデータを処理中')
    success_error_array = client.refresh(date: Time.zone.today - 1.months, period: 1.months)
    message&.update(state: true, message: "楽天ーヶ月データ(#{success_error_array[0]}件)更新完了. エラー: #{success_error_array[1]}")
    client = nil
    GC.start
  end
end
