class MailerWorker
  include Sidekiq::Worker

  def perform(oyster_invoice_id = nil, message_id = nil)
    if oyster_invoice_id.nil? && message_id.nil?
      send_all_unsent
    else
      send_invoice(oyster_invoice_id, message_id)
    end
  end

  def send_all_unsent
    OysterInvoice.where(completed: false).each do |invoice|
      next unless invoice.send_at <= Time.zone.now

      InvoiceMailer.with(invoice:).sakoshi_invoice_email.deliver_now
      InvoiceMailer.with(invoice:).aioi_invoice_email.deliver_now
      invoice.completed = true
      invoice.data[:mail_sent] = Time.zone.now
      invoice.save
    end
  end

  def send_invoice(oyster_invoice_id, message_id)
    @oyster_invoice = OysterInvoice.find(oyster_invoice_id)
    @message = Message.find(message_id)
    InvoiceMailer.with(invoice: @oyster_invoice).sakoshi_invoice_email.deliver_now
    InvoiceMailer.with(invoice: @oyster_invoice).aioi_invoice_email.deliver_now
    @oyster_invoice.completed = true
    @oyster_invoice.data[:mail_sent] = Time.zone.now
    @oyster_invoice.save
    @message.state = true
    @message.message = 'メールを送信しました。'
    @message.save
  end
end
