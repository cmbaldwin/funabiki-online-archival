class YahooUpdateWorker
  include Sidekiq::Worker

  def perform(message_id = nil)
    message = Message.find(message_id) if message_id
    client = YahooAPIv2.new
    client.acquire_auth_token unless client.authorized?
    return puts 'Manual re-authentication required to process new Yahoo! orders' unless client.authorized?

    message&.update(message: '処理中...')
    client.capture_orders
    client.update_processing
    message&.update(state: true, message: 'ヤフー注文データ更新完了。', data: { expiration: (DateTime.now + 1.minute) })
    client = nil
    GC.start
  end
end
