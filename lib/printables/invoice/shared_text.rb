# frozen_string_literal: true

class Invoice
  # Supplier Invoice shared static text module - Mixin for Supplier Invoice PDF generator
  module SharedText
    def sakoshi_union_info
      <<~INFO
        <b>〒678-0215 </b>
        兵庫県赤穂市御崎1798－1
        赤穂市漁業協同組合
        TEL 0791(45)2260 FAX 0791(45)2261
      INFO
    end

    def aioi_union_info
      <<~INFO
        <b>〒678-0041 </b>
        兵庫県相生市相生３丁目４−２２
        相生漁業協同組合
        TEL  0791(22)0344
      INFO
    end

    def unions_info
      case @location
      when 'sakoshi' then sakoshi_union_info
      when 'aioi' then aioi_union_info
      end
    end

    def print_location
      case @location
      when 'sakoshi' then '坂越'
      when 'aioi' then '相生'
      end
    end

    def print_union_name
      case @location
      when 'sakoshi' then '赤穂市漁業協同組合'
      when 'aioi' then '相生漁業協同組合'
      end
    end

    def print_union_invoice_number
      case @location
      when 'sakoshi' then 'T4-1400-0500-7543'
      when 'aioi' then 'T3-1400-0500-7544'
      end
    end

    def tax_warning_text
      move_down 20
      text '※ 軽減税率対象', align: :center
    end

    def document_title
      case @format
      when 'union' then "<b>（#{print_location}）支払明細書</b>"
      when 'supplier' then "<b>〔#{@current_supplier.supplier_number}〕 #{@current_supplier.company_name} ― 支払明細書</b>"
      end
    end
  end
end
