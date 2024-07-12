module Oroshi
  class InvoiceWorker
    include Sidekiq::Worker

    def perform(invoice_id, message_id)
      message = Message.find(message_id)
      @invoice = Invoice.find(invoice_id)
      create_or_refresh_invoices
      message.update(state: true, message: '供給料仕切り書作成完了')
    end

    def create_or_refresh_invoices
      @invoice.invoice_supplier_organizations.each do |join|
        reset_join(join)
        %w[organization supplier].each do |invoice_format|
          password = SecureRandom.hex(4)
          invoice = join.invoices.attach(io: generate_pdf(join, invoice_format, password),
                                         content_type: 'application/pdf',
                                         filename: filename(join, invoice_format)).last
          @passwords[invoice.id] = password
        end
        join.update!(passwords: @passwords, completed: true)
      end
    end

    def reset_join(join)
      join.transaction do
        join.invoices.purge
        join.update!(passwords: {})
        join.completed = false
      end
      @passwords = {}
    end

    def generate_pdf(join, invoice_format, password)
      pdf = OroshiInvoice.new(@invoice.start_date, @invoice.end_date,
                              supplier_organization: join.supplier_organization.id,
                              invoice_format: invoice_format,
                              layout: @invoice.invoice_layout,
                              password: password)
      string = StringIO.new pdf.render
      pdf = nil
      string
    end

    def filename(join, invoice_format)
      "#{join.supplier_organization.entity_name}
      (#{@invoice.start_date} ~ #{@invoice.end_date}) - #{template_format_name(invoice_format)}
      [#{DateTime.now.strftime('%Y%m%d%H%M%S')}].pdf".squish
    end

    def template_format_name(invoice_format)
      format_name = invoice_format == 'organization' ? '組織-' : '生産者-'
      template_name = @invoice.invoice_layout == 'standard' ? '標準版' : '簡易版'
      format_name + template_name
    end
  end
end
