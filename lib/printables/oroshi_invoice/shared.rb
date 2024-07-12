# frozen_string_literal: true

class OroshiInvoice
  # Supplier Invoice shared static text module - Mixin for Supplier Invoice PDF generator
  module Shared
    def organization_info
      <<~INFO
        <b>#{@supplier_organization.address.postal_code} </b>
        #{@supplier_organization.address.invoice_line}
        #{@supplier_organization.entity_name}
        #{phone_and_fax(@supplier_organization.phone, @supplier_organization.fax)}
      INFO
    end

    def funabiki_info_text
      settings = Setting.find_by(name: 'oroshi_company_settings')&.settings
      return company_info_text_backup unless settings

      <<~INFO
        #{settings['postal_code']}
        #{settings['address']}
        #{phone_and_fax(settings['phone'], settings['fax'])}
        メール: #{settings['mail']}
        #{settings['name']}

        ※送付後一定期間内に連絡がない場合確認済とします
      INFO
    end

    def company_info_text_backup
      <<~INFO
        〒678-0232
        兵庫県赤穂市中広1576－11
        TEL (0791)43-6556 FAX (0791)43-8151
        メール info@funabiki.info
        株式会社船曳商店

        ※送付後一定期間内に連絡がない場合確認済とします
      INFO
    end

    def tax_warning_text
      move_down 20
      text '※ 軽減税率対象', align: :center
    end

    def document_title
      case @invoice_format
      when 'organization' then "<b>#{@supplier_organization.entity_name} ― 支払明細書</b>"
      when 'supplier' then "<b>〔#{@current_supplier.supplier_number}〕 #{@current_supplier.company_name} ― 支払明細書</b>"
      end
    end

    def print_supply_dates
      localize_supply_date = ->(supply_date) { l(supply_date.date, format: :long) }
      "#{localize_supply_date.call(supply_dates.first)} ~ #{localize_supply_date.call(supply_dates.last)}"
    end

    def en_it(num, unit: '円', delimiter: ',')
      yenify(num, unit:, delimiter:)
    end

    def spacer
      [{ content: '', colspan: 3, size: 8, padding: 2, align: :center }]
    end
  end
end
