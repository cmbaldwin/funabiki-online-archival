class RecieptWorker
  include Sidekiq::Worker

  def perform(options, message_id)
    message = Message.find(message_id)
    pdf_data = Receipt.new(options)
    pdf = pdf_data.render
    io = StringIO.new pdf
    message.stored_file.attach(io:, content_type: 'application/pdf', filename: message.data[:filename])
    message&.update(state: true, message: '領収証作成完了。')
    pdf_data = nil
    io = nil
    GC.start
  end
end
