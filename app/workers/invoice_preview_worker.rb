class InvoicePreviewWorker
  include Sidekiq::Worker

  def perform(start_date, end_date, location, format, layout, message_id)
    message = Message.find(message_id)
    pdf = Invoice.new(Date.parse(start_date), Date.parse(end_date), location:, format:, layout:)
    message.data[:filename] =
      "#{location} (#{start_date} ~ #{end_date}) - #{format}[#{DateTime.now.strftime('%Y%m%d%H%M%S')}].pdf"
    io = StringIO.new pdf.render
    message.stored_file.attach(io:, content_type: 'application/pdf', filename: message.data[:filename])
    message.update(state: true, message: '牡蠣原料仕切りプレビュー作成完了')
    pdf = nil
    io = nil
    GC.start
  end
end
