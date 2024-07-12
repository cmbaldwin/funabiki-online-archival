class SupplyCheck
  # Header and Footer module
  module HeaderAndFooter
    def header
      [
        [header_title, header_guidelines, header_admin],
        *header_stamp,
        spacer,
        date_time_header
      ]
    end

    def footer
      [
        *footer_guidelines,
        [info_cell, logo_cell, created_modified_cell]
      ]
    end

    private

    # Title, confirmations and guidelines

    def header_title
      { content: "供給・受入チェック表<br>（#{@supplier_organizations.first.subregion.name}）",
        colspan: 4, rowspan: 3, size: 14, padding: 7,
        align: :center, valign: :center, font_style: :bold, leading: 8 }
    end

    def header_guidelines
      guidelines = <<~GUIDELINES
        〇＝適切　X＝不適切
        不適切な場合は備考欄に日付と
        説明を書いてください。
      GUIDELINES
      { content: guidelines, colspan: 2, rowspan: 3, size: 8, align: :center,
        valign: :center, leading: 4 }
    end

    def header_admin
      { content: '日付', colspan: 2, size: 7, padding: 1, align: :left, valign: :center }
    end

    def header_stamp
      [
        [{ content: "\u793E\u9577", padding: 3 }, { content: "\u54C1\u7BA1", padding: 3 }],
        [{ content: ' <br> ', padding: 3 }, { content: ' <br> ', padding: 3 }]
      ]
    end

    def date_time_header
      [
        { content: I18n.l(@supply_date.date, format: :long), colspan: 4, size: 10, align: :center },
        { content: @current_supply_reception_time.time_qualifier, colspan: 4, size: 10, align: :center }
      ]
    end

    # Footer guidlines

    def footer_guidelines
      [
        spacer,
        [{ content: footer_guideline_part1, colspan: 4, padding: 5, size: 7 },
         { content: footer_guideline_part2, colspan: 4, padding: 5, size: 7 }],
        spacer
      ]
    end

    def footer_guideline_part1
      <<~GUIDELINE_PART_1
        ● 記録の頻度: 入荷ごとに海域および生産者別に行う。
        ● 備考欄に生産者の牡蠣の質・状態についての一言を記入する、または
        最終判定が×の場合、その理由と措置を記入する
        ● 判定基準: 漁獲場所、むき身の量、生産者の名前または記録番号を
        記載するタグを確認する
      GUIDELINE_PART_1
    end

    def footer_guideline_part2
      <<~GUIDELINE_PART_2
        ● 判定基準（続き）
        官能検査：見た目で異常がなく、異臭等が無いこと。
        品温: 0~20℃ ・ pH: 6.0~8.0 ・ 塩分: 0.5%以上
        最終判定：上記項目およびその他に異常がなく、原料として受け入れられるもの。
      GUIDELINE_PART_2
    end

    # Bottom of the page

    def info_cell
      { content: company_info, size: 8, padding: 2, colspan: 3 }
    end

    def logo_cell
      { image: funabiki_logo, scale: 0.065, colspan: 2, position: :center }
    end

    def created_modified_cell
      created_modified = <<~DATES
        <b><font size="12">作成日・更新日</font></b>
        2019年05月31日
        2024年03月01日
      DATES
      { content: created_modified, size: 10, padding: 2, colspan: 3, align: :right }
    end
  end
end
