class RakutenProcessWorker
  include Sidekiq::Worker

  def perform(message_id = nil)
    message = Message.find(message_id) if message_id

    client = Rakuten::Api.new
    unprocessed_ids = client.unprocessed_order_ids
    message&.update(message: "楽天で自動処理されていない新規#{unprocessed_ids.length}件があります。")

    client.automate(orders: client.order_details(unprocessed_ids), debug: false)
    message&.update(state: true, message: '自動処理完了')
    client = nil
    GC.start
  end
end
