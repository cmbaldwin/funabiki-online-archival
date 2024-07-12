class OnlineOrdersShippingListWorker
  include Sidekiq::Worker

  def perform(ship_date, message_id, filename)
    message = Message.find(message_id)
    pdf_data = PrawnPDF.online_orders(ship_date, filename)
    io = StringIO.new pdf_data.render
    message.stored_file.attach(io:, content_type: 'application/pdf', filename: message.data[:filename])
    message.update(state: true, message: 'Funabiki.info出荷表作成完了')
    pdf_data = nil
    io = nil
    GC.start
  end
end
