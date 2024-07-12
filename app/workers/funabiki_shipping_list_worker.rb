class FunabikiShippingListWorker
  include Sidekiq::Worker

  def perform(ship_date, message_id)
    message = Message.find(message_id) if message_id
    pdf_data = OnlineShopPackingList.new(ship_date:, included: %w[funabiki])
    io = StringIO.new pdf_data.render
    message.stored_file.attach(io:, content_type: 'application/pdf', filename: 'funabiki_orders_list.pdf')
    message&.update(state: true, message: 'Funabiki.info出荷表作成完了')
    pdf_data = nil
    io = nil
    GC.start
  end
end
