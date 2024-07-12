class SolidusApiWorker
  include Sidekiq::Worker

  def perform(message_id = nil)
    client = SolidusAPI.new
    unfinished_orders = FunabikiOrder.unfinished.map(&:details)
    client.fetch_order_details(unfinished_orders)
    client.save_orders
    client.save('new_orders')
    client.save('processed_orders')
    return unless message_id

    message = Message.find(message_id)
    message.update(state: true, message: 'Funabiki.info注文データを更新しました')

    client = nil
    GC.start
  end
end
