class RakutenRefreshWorker
  include Sidekiq::Worker

  def perform(date, message_id = nil)
    date = Date.parse(date) if date.is_a?(String)
    message = Message.find(message_id) if message_id
    client = Rakuten::Api.new
    message&.update(message: "楽天の#{date}データを更新中")
    success_error_array = client.refresh(date: date, period: 1.day)
    message&.update(state: true, message: "楽天の#{date}データ(#{success_error_array[0]}件)更新完了. エラー: #{success_error_array[1]}")
    client = nil
    GC.start
  end
end
