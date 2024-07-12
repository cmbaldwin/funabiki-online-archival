class OysterSupplyCheck
  # Header and Footer module
  module HeaderAndFooter
    def header
      [
        [header_guidelines, header_title, header_admin],
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

    def date_time_header
      [
        { content: @supply.supply_date, colspan: 5, size: 10, align: :center },
        { content: @supply.kanji_am_pm(@current_receiving_time), colspan: 2, size: 10, align: :center },
        { content: '時刻:', colspan: 3, size: 10, align: :left }
      ]
    end

    def footer_guideline_part1
      <<~GUIDELINE_PART_1
        ●記録の頻度
        入荷ごとに海域および生産者別に行う。
        ●備考欄に生産者の牡蠣の質・状態についての一言を記入する、または 最終判定が×の場合、その理由と措置を記入する
        ●判定基準
        漁獲場所、むき身の量、生産者の名前または記録番号を記載するタグを確認する
      GUIDELINE_PART_1
    end

    def footer_guideline_part2
      <<~GUIDELINE_PART_2
        ●判定基準（続き）
        官能検査：見た目で異常がなく、異臭等が無いこと。
        品温：０～20℃
        ｐH：6.0～8.0
        塩分：0.5％以上
        最終判定：上記項目およびその他に異常がなく、原料として受け入れられるもの。
      GUIDELINE_PART_2
    end

    def footer_guidelines
      [
        [{ content: '', colspan: 10, padding: 3 }],
        [{ content: footer_guideline_part1, colspan: 5, padding: 5, size: 8 },
         { content: footer_guideline_part2, colspan: 5, padding: 5, size: 8 }],
        [{ content: '', colspan: 10, padding: 3 }]
      ]
    end

    def info_cell
      { content: company_info, size: 8, padding: 3, colspan: 3 }
    end

    def logo_cell
      { image: funabiki_logo, scale: 0.065, colspan: 4, position: :center }
    end

    def created_modified_cell
      created_modified = <<~DATES
        <b><font size="12">作成日・更新日</font></b>
        2019年05月31日
        2023年01月26日
      DATES
      { content: created_modified, size: 10, padding: 3, colspan: 3, align: :right }
    end

    def header_guidelines
      guidelines = <<~GUIDELINES
        〇＝適切　X＝不適切
        不適切な場合は備考欄に日付と
        説明を書いてください。
      GUIDELINES
      { content: guidelines, colspan: 3, rowspan: 3, size: 9, align: :center,
        valign: :center }
    end

    def header_title
      { content: '(マガキ)生牡蠣原料受入表①<br>（兵庫県産）', colspan: 5, rowspan: 3, size: 14, padding: 7,
        align: :center, valign: :center, font_style: :bold }
    end

    def header_admin
      { content: '確認日付', colspan: 2, size: 7, padding: 1, align: :left, valign: :center }
    end

    def header_stamp
      [
        [{ content: "\u793E\u9577", padding: 3 }, { content: "\u54C1\u7BA1", padding: 3 }],
        [{ content: ' <br> ', padding: 3 }, { content: ' <br> ', padding: 3 }]
      ]
    end
  end
end
