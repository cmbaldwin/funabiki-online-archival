class OysterSupplyCheckWorker
  include Sidekiq::Worker

  def perform(oyster_supply_id, message_id, receiving_times)
    message = Message.find(message_id)
    supply = OysterSupply.find(oyster_supply_id)
    pdf_data = OysterSupplyCheck.new(supply, receiving_times: receiving_times || %(am pm))
    io = StringIO.new pdf_data.render
    message.stored_file.attach(io: io, content_type: "application/pdf", filename: message.data[:filename])
    message.update(state: true, message: '牡蠣原料受入れチェック表作成完了。')
    pdf_data = nil
    io = nil
    GC.start
  end
end
