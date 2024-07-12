class InvoiceMailer < ApplicationMailer
  require 'open-uri'
  default from: ENV['MAIL_SENDER']

  # These are the old email methods that were used to send the invoices to the customers.

  def sakoshi_invoice_email
    @invoice = params[:invoice]
    @locale = '坂越'
    process_attachments
    mail(to: @invoice[:sakoshi_emails], subject: '船曳商店ー支払い明細書 ' + @locale + '（' + @invoice.display_date + '）')
  end

  def aioi_invoice_email
    @invoice = params[:invoice]
    @locale = '相生'
    process_attachments
    mail(to: @invoice[:aioi_emails], subject: '船曳商店ー支払い明細書 ' + @locale + '（' + @invoice.display_date + '）')
  end

  def process_attachments
    locale_map = { '坂越' => 'sakoshi', '相生' => 'aioi' }
    prefix = locale_map[@locale]

    %w[collected_invoice individual_invoice].each do |type|
      file = @invoice.public_send("#{prefix}_#{type}")
      attachments[file.filename.to_s] = {
        mime_type: file.content_type,
        content: file.download
      }
    end
  end

  # InvoiceMailer.test_mail.deliver_now
  def test_mail
    mail(to: ENV['MAIL_SENDER'], subject: 'Test')
  end
end
