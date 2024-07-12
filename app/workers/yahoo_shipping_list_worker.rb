class YahooShippingListWorker
  include Sidekiq::Worker

  def perform(ship_date, message_id, _filename)
    message = Message.find(message_id) if message_id
    pdf_data = OnlineShopPackingList.new(ship_date:, included: %w[yahoo])
    io = StringIO.new pdf_data.render
    message.stored_file.attach(io:, content_type: 'application/pdf', filename: message.data[:filename])
    message&.update(state: true, message: 'ヤフー出荷表作成完了')
    pdf_data = nil
    io = nil
    GC.start
  end
end
