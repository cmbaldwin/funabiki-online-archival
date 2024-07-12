module Oroshi
  class SupplyCheckWorker
    include Sidekiq::Worker

    def perform(supply_date, message_id, subregion_ids, supply_reception_time_ids)
      message = Message.find(message_id)
      @supply_date = Oroshi::SupplyDate.find_by(date: supply_date)
      pdf_data = SupplyCheck.new(supply_date, subregion_ids, supply_reception_time_ids)
      io = StringIO.new pdf_data.render
      message.stored_file.attach(io: io, content_type: "application/pdf", filename: message.data[:filename])
      message.update(state: true, message: '牡蠣原料受入れチェック表作成完了。')
      pdf_data = nil
      io = nil
      GC.start
    end
  end
end
