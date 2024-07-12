class InfomartShippingListWorker
  include Sidekiq::Worker

  def perform(ship_date, message_id, blank)
    message = Message.find(message_id)
    pdf = RestaurantPackingList.new(ship_date: Date.parse(ship_date), blank: !blank.to_i.zero?)
    io = StringIO.new pdf.render
    message.stored_file.attach(io:, content_type: 'application/pdf', filename: message.data[:filename])
    message.update(state: true, message: 'Infomart出荷表作成完了')
    pdf = nil
    io = nil
    GC.start
  end
end
