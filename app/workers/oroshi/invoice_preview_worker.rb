module Oroshi
  class InvoicePreviewWorker
    include Sidekiq::Worker

    def perform(start_date, end_date, supplier_organization, invoice_format, layout, message_id)
      message = Message.find(message_id)
      pdf = OroshiInvoice.new(Date.parse(start_date), Date.parse(end_date),
                              supplier_organization:, invoice_format:, layout:)
      message.data[:filename] = filename(supplier_organization, start_date, end_date, invoice_format)
      io = StringIO.new pdf.render
      message.stored_file.attach(io:, content_type: 'application/pdf', filename: message.data[:filename])
      message.update(state: true, message: '供給料仕切り書プレビュー作成完了')
      pdf = nil
      io = nil
      GC.start
    end

    def filename(supplier_organization, start_date, end_date, invoice_format)
      "#{Oroshi::SupplierOrganization.find(supplier_organization).entity_name}
      (#{start_date} ~ #{end_date}) - #{invoice_format}
      [#{DateTime.now.strftime('%Y%m%d%H%M%S')}].pdf".squish
    end
  end
end
