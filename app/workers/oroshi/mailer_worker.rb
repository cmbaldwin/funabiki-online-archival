module Oroshi
  class MailerWorker
    include Sidekiq::Worker

    def perform(invoice_id = nil, message_id = nil)
      if invoice_id.nil? || message_id.nil?
        send_all_unsent
      else
        invoice = Oroshi::Invoice.find(invoice_id)
        message = Message.find(message_id)
        send_invoices(invoice, message)
      end
    end

    def send_all_unsent
      Oroshi::Invoice.unsent.each do |invoice|
        send_invoices(invoice, message)
      end
    end

    def send_invoices(invoice, message = nil)
      if send_invoice_notifications(invoice)
        invoice.sent_at = Time.zone.now
        invoice.save
        message&.state = true
        message&.message = 'メールを送信しました。'
      else
        message&.state = false
        message&.message = 'メールの送信に失敗しました。'
      end
      message&.save
    end

    def send_invoice_notifications(invoice)
      invoice.invoice_supplier_organizations.each do |invoice_supplier_organization|
        next if send_invoice_notification(invoice_supplier_organization)

        Rails.logger.error("Failed to send email for invoice: #{invoice.id}")
        Rails.logger.error(invoice.errors.full_messages)
        return false
      end
    end

    def send_invoice_notification(invoice_supplier_organization)
      unless invoice_supplier_organization.completed
        return Rails.logger
                    .error("Error trying to send an incomplete invoice_supplier_organization: #{id}")
      end

      id = invoice_supplier_organization.id
      mail = Oroshi::InvoiceMailer.invoice_notification(id)
      if mail.deliver_now
        invoice_supplier_organization.sent_at = Time.zone.now
        invoice_supplier_organization.completed = true
        invoice_supplier_organization.save
      else
        Rails.logger.error("Failed to send email for invoice_supplier_organization: #{id}")
        Rails.logger.error(mail.errors.full_messages)
        Rails.logger.error(invoice_supplier_organization.errors.full_messages)
        false
      end
    end
  end
end
