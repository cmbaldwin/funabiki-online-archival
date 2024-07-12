class ManifestPdfWorker
  include Sidekiq::Worker

  def perform(manifest_id, message_id)
    message = Message.find(message_id)
    @manifest = Manifest.find(manifest_id)
    pdf_data = PrawnPDF.manifest(@manifest)
      io = StringIO.new pdf_data.render
      message.stored_file.attach(io: io, content_type: "application/pdf", filename: message.data[:filename])
    message.update(state: true, message: 'InfoMart/Funabiki.infoの出荷表作成完了。')
    pdf_data = nil
    io = nil
    GC.start
  end
end
