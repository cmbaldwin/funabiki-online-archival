# frozen_string_literal: true

# Forcast Helper
module ForcastHelper
  def print_range(range)
    content_tag :div, class: 'card-title text-center fs-6' do
      <<~RANGE.strip_heredoc.html_safe
        <b>#{to_nengapiyoubi(range.first)}</b> から<br>
        <b>#{to_nengapiyoubi(range.last)}</b> まで
      RANGE
    end
  end

  def print_calender_count(prefix, figure)
    return unless figure&.positive?

    "<div class='d-none d-lg-inline fw-lighter'>#{prefix}：</div>#{figure}<br>"
  end
end
