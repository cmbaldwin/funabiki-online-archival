# frozen_string_literal: true

# Experation Card PDF Generator
class ShellCard < Printable
  def initialize(card_id)
    super()
    @card = ExpirationCard.find(card_id)
    font_size 9
    generate_pdf
  end

  def generate_pdf
    table(cards_table, cell_style: card_table_style, width: bounds.width) { |t| printer_margins(t) }
  end

  def cards_table
    spacer = [' ', ' ']
    cards = [spacer]
    5.times do
      cards << [{ content: one_shell_card }, { content: one_shell_card }]
      cards << spacer
    end
    cards
  end

  def one_shell_card
    make_table(
      shell_card_base,
      cell_style: shell_card_style,
      width: (bounds.width / 2 - 25),
      column_widths: { 0 => 75 }
    )
  end

  def shell_card_base
    shell_card = [
      [' 名                 称', "<b>#{@card.product_name}</b>"],
      [' 加工 所 所 在地', @card.manufacturer_address],
      [' 加      工      者', @card.manufacturer],
      [' 採    取    海    域', @card.ingredient_source],
      [' 用                 途', @card.consumption_restrictions],
      [' 保    存    温    度', @card.storage_recommendation]
    ]
    shell_card << [' 製  造  年  月  日', { content: @card.manufactuered_date, align: :center }] if @card.made_on
    shell_card << [@card.print_shomiorhi, { content: @card.expiration_date, align: :center }]
  end

  def shell_card_style
    {
      border_width: 0.25,
      valign: :center,
      inline_format: true,
      padding: 4,
      height: 17
    }
  end

  def printer_margins(table)
    table.column(1).padding = [0, 0, 0, 25] # Spacer right printer margin
    table.column(0).padding = [0, 0, 0, 7] # Cards right printer margin
    table.cells.style do |c|
      c.height = 30 if (c.row % 2).zero? # Non spacer row height (even row #s)
    end
    table.row(0).height = 5 # Spacer row height
    table.row(-1).height = 0 # Bottom spacer row height
  end

  def card_table_style
    { border_width: 0, valign: :center, padding: 0 }
  end
end
