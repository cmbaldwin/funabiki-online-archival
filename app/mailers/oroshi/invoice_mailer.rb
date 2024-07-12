module Oroshi
  class InvoiceMailer < ApplicationMailer
    require 'open-uri'

    def invoice_notification(invoice_supplier_organization_id)
      @invoice_supplier_organization = Oroshi::Invoice::SupplierOrganization.find(invoice_supplier_organization_id)
      @header = header.gsub("\n", '<br>').strip
      @company_info = company_info
      process_attachments
      mail(to: @invoice_supplier_organization.supplier_organization.email,
           from: default_from,
           cc: Setting.find_by(name: 'oroshi_company_settings')&.settings&.dig('mail'),
           subject: subject.gsub("\n", ' ').strip,
           template_path: 'oroshi/invoices/mailer')
    end

    def process_attachments
      @invoice_supplier_organization.invoices.each do |invoice|
        invoice.blob.open do |file|
          attachments[invoice.blob.filename.to_s] = file.read
        end
      end
    end

    def company_info
      settings = Setting.find_by(name: 'oroshi_company_settings')&.settings
      return company_info_text_backup unless settings

      <<~INFO
        <b>#{settings['name']}</b><br>
        〒#{settings['postal_code']}<br>
        #{settings['address']}<br>
        #{phone_and_fax(settings['phone'], settings['fax'])}<br>
        メール: #{settings['mail']}<br>
      INFO
    end

    def company_info_text_backup
      "<b>(株)船曳商店</b><br>
        〒678-0232<br>
        兵庫県赤穂市1576－11<br>
        TEL (0791)43-6556 FAX (0791)43-8151<br>
        メール info@funabiki.info<br>"
    end

    def phone_and_fax(phone, fax)
      print_non_nil = ->(prefix, text) { "#{prefix} #{text}" if text }
      "#{print_non_nil['TEL', phone]}<br>
      #{print_non_nil['FAX', fax]}"
    end

    private

    def default_from
      ENV.fetch('MAIL_SENDER', nil) || Setting.find_by(name: 'oroshi_company_settings')&.settings&.dig('mail')
    end

    def subject
      company_name = Setting.find_by(name: 'oroshi_company_settings')&.settings&.dig('name')
      invoice = @invoice_supplier_organization.invoice
      supplier_organization = @invoice_supplier_organization.supplier_organization
      date_range_string = [invoice.start_date, invoice.end_date]
                          .map { |date| l(date, format: :long) }
                          .join(' 〜 ')
      <<~HEREDOC
        #{company_name} ー #{supplier_organization.micro_region} 支払い明細書（#{date_range_string}）
      HEREDOC
    end

    def header
      invoice = @invoice_supplier_organization.invoice
      supplier_organization = @invoice_supplier_organization.supplier_organization
      date_range_string = [invoice.start_date, invoice.end_date]
                          .map { |date| l(date, format: :long) }
                          .join(' 〜 ')
      <<~HEREDOC
        #{supplier_organization.entity_name}
        (#{supplier_organization.subregion} - #{supplier_organization.micro_region} )
        【 #{date_range_string} 】の 支払い明細書
      HEREDOC
    end
  end
end
