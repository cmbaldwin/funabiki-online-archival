class RakutenManifestWorker
  include Sidekiq::Worker

  def perform(ship_date, sectioned, message_id, include_tsuhan)
    message = Message.find(message_id)
    ship_date = Date.parse(ship_date)
    included = include_tsuhan ? %w[rakuten yahoo funabiki] : %w[rakuten]
    pdf_data = OnlineShopPackingList.new(ship_date:, included:, sectioned:)
    io = StringIO.new pdf_data.render
    message.stored_file.attach(io:, content_type: 'application/pdf', filename: message.data[:filename])
    message.update(state: true, message: '楽天出荷表作成完了')
    pdf_data = nil
    io = nil
    GC.start
  end
end
