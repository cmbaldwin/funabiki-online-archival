class ProcessInvoiceWorker
  include Sidekiq::Worker

  def perform(invoice_id, message_id)
    invoice = OysterInvoice.find(invoice_id)
    msg = Message.find(message_id)
    invoice.data[:message] = message_id
    start_date = Date.parse(invoice.start_date)
    end_date = Date.parse(invoice.end_date)
    print_start_date = start_date.strftime('%Y年%m月%d日')
    print_end_date = end_date.strftime('%Y年%m月%d日')

    # Sakoshi All Suppliers
    pdf = Invoice.new(start_date, end_date,
                      location: 'sakoshi', format: 'union', layout: 2,
                      password: invoice[:data][:passwords]['sakoshi_all_password'],
                      invoice_date: invoice.send_at.to_date)
    filename = "坂越_生産者まとめ_#{print_start_date}_#{print_end_date}"
    io = StringIO.new pdf.render
    invoice.sakoshi_collected_invoice.attach(io:, content_type: 'application/pdf', filename:)
    invoice.save
    pdf = nil
    io = nil

    # Sakoshi Individual
    invoice.reload
    pdf = Invoice.new(start_date, end_date,
                      location: 'sakoshi', format: 'supplier', layout: 2,
                      password: invoice[:data][:passwords]['sakoshi_seperated_password'],
                      invoice_date: invoice.send_at.to_date)
    filename = "坂越_各生産者_#{print_start_date}_#{print_end_date}"
    io = StringIO.new pdf.render
    invoice.sakoshi_individual_invoice.attach(io:, content_type: 'application/pdf', filename:)
    invoice.save
    pdf = nil
    io = nil

    # Aioi All Suppliers
    invoice.reload
    pdf = Invoice.new(start_date, end_date,
                      location: 'aioi', format: 'union', layout: 2,
                      password: invoice[:data][:passwords]['aioi_all_password'],
                      invoice_date: invoice.send_at.to_date)
    filename = "相生_生産者まとめ_#{print_start_date}_#{print_end_date}"
    io = StringIO.new pdf.render
    invoice.aioi_collected_invoice.attach(io:, content_type: 'application/pdf', filename:)
    invoice.save
    pdf = nil
    io = nil

    # Aioi Individual
    invoice.reload
    pdf = Invoice.new(start_date, end_date,
                      location: 'aioi', format: 'supplier', layout: 2,
                      password: invoice[:data][:passwords]['aioi_seperated_password'],
                      invoice_date: invoice.send_at.to_date)
    filename = "相生_各生産者_#{print_start_date}_#{print_end_date}"
    io = StringIO.new pdf.render
    invoice.aioi_individual_invoice.attach(io:, content_type: 'application/pdf', filename:)
    invoice.data[:processing] = false
    invoice.save
    pdf = nil
    io = nil
    msg.update(state: true, message: '牡蠣原料仕切り作成完了')
    GC.start
  end
end
