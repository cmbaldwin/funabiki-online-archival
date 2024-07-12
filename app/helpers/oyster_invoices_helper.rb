module OysterInvoicesHelper

  def invoice_display_date(invoice)
    invoice.start_date + ' ~ ' + (Date.parse(invoice.end_date) - 1.day).to_s
  end

  def processing_link(oyster_invoice, url_method)
    link_text = if oyster_invoice.data[:processing]
                  '<div class="spinner-border spinner-border-sm"></div>'
                else
                  "<div class='text-primary'>#{icon('file-arrow-down')} ダウンロード</div>"
                end
    link_to link_text.html_safe,
            oyster_invoice.send(url_method).url,
            target: '_blank',
            class: 'btn btn-sm btn-light',
            data: { turbo_prefetch: false }
  end

  def nearest_thursday_at_nine
    Time.zone.now.next_occurring(:thursday).change(hour: 9)
  end

  def password_cell(oyster_invoice, password)
    content_tag :td,
                class: "cursor-pointer tippy",
                data: {
                  controller: "tippy",
                  tippy_content: "クリックしてコピー"
                } do
                  content_tag :samp,
                              oyster_invoice[:data][:passwords][password],
                              data: {
                                action: "click->oyster-supplies--invoice#copy"
                              }
    end
  end

end
