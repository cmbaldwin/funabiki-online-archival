# frozen_string_literal: true

# Restaurant Order Packing Lists PDF Generator
class EmptyTemplate < Printable
  def initialize(orders, filename)
    super()
    @orders = orders
    generate_pdf
    render_file filename
  end

  def generate_pdf
    text 'test'
  end
end
