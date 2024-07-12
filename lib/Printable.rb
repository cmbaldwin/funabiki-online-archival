# FrozenStringLiteral: true

require 'prawn'
require 'prawn/table'
require 'open-uri'

# Printable - PrawnPDF Initializer
class Printable < Prawn::Document
  # Usage: class MyDocument < Printable
  #          def initialize
  #            super
  #            # ... do stuff
  #          end
  #        end
  #        MyDocument.new.render_file('my_document.pdf')
  # Or, render to io and attach to model with ActiveStorage:
  #        io = StringIO.new MyDocument.new.render
  #        model.file.attach(io: io, content_type: 'application/pdf', filename: 'my_document.pdf')

  def initialize(page_size: 'A4', page_layout: :portrait, margin: [15])
    super(page_size:, page_layout:, margin:)
    font_families.update(fonts)
    font 'MPLUS1p' # default font
  end

  def company_info
    settings = Setting.find_by(name: 'oroshi_company_settings')&.settings
    return company_info_text_backup unless settings

    <<~INFO
      <b>〒#{settings['postal_code']} </b>
      #{settings['address']}
      #{settings['name']}
      #{phone_and_fax(settings['phone'], settings['fax'])}
      メール: #{settings['mail']}
    INFO
  end

  def company_info_text_backup
    "<b>〒678-0232</b>
      兵庫県赤穂市1576－11
      (株)船曳商店
      TEL (0791)43-6556 FAX (0791)43-8151
      メール info@funabiki.info"
  end

  def phone_and_fax(phone, fax)
    print_non_nil = ->(prefix, text) { "#{prefix} #{text}" if text }
    "#{print_non_nil['TEL', phone]} #{print_non_nil['FAX', fax]}"
  end

  def rakuten_info
    <<~RAKUTEN_INFO
      株式会社船曳商店 　
      OYSTER SISTERS
      〒678-0232
      兵庫県赤穂市中広1576－11
      TEL: 0791-42-3645
      FAX: 0791-43-8151
      店舗運営責任者: 船曳　晶子
    RAKUTEN_INFO
  end

  def funabiki_info
    <<~FUNABIKI_INFO
      株式会社船曳商店 　
      〒678-0232
      兵庫県赤穂市中広1576－11
      TEL: 0791-42-3645
      FAX: 0791-43-8151
      メール: info@funabiki.info
      ウエブ: www.funabiki.info
    FUNABIKI_INFO
  end

  def invoice_number
    "登録番号 T3140002034095"
  end

  private

  def fonts
    {
      'MPLUS1p' => mplus_font_paths,
      'Sawarabi' => sawarabi_font_paths,
      'TakaoPMincho' => takao_font_path
    }
  end

  def mplus_font_paths
    {
      normal: root('.fonts/MPLUS1p-Regular.ttf'),
      bold: root('.fonts/MPLUS1p-Bold.ttf'),
      light: root('.fonts/MPLUS1p-Light.ttf')
    }
  end

  def sawarabi_font_paths
    # Must be used for names, this font includes almost all Japanese characters
    { normal: root('.fonts/SawarabiMincho-Regular.ttf') }
  end

  def takao_font_path
    { normal: root('.fonts/TakaoPMincho.ttf') }
  end

  def root(file)
    Rails.root.join(file)
  end

  def oysis_logo
    root('app/assets/images/oysis.jpg')
  end

  def funabiki_logo
    root('app/assets/images/logo_ns.png')
  end

  def jp_format(date)
    date.strftime('%Y年%m月%d日')
  end

  def funabiki_header(alt_address)
    funa_cell = { content: funabiki_info, size: 8 }
    alt_cell = { content: alt_address, size: 8 }
    [alt_cell, { image: funabiki_logo, scale: 0.065, position: :center }, funa_cell]
  end

  def funabiki_footer(format_created_date, _format_updated_date)
    funa_cell = { content: funabiki_info, size: 10, padding: 3, colspan: 3 }
    logo_cell = { image: @funabiki_logo, scale: 0.065, colspan: 4, position: :center }
    created_cell = { content: %(
      <b><font size="12">作成日・更新日</font></b>
      #{jp_format(format_created_date)}
      #{jp_format(format_updates_date)}
      ), size: 10, padding: 3, colspan: 3, align: :right }
    [funa_cell, logo_cell, created_cell]
  end

  def fetch_cached_suppliers
    @sakoshi_suppliers = Rails.cache.fetch 'sakoshi_suppliers' do
      Supplier.where(location: '坂越').order(:supplier_number)
    end
    @aioi_suppliers = Rails.cache.fetch 'aioi_suppliers' do
      Supplier.where(location: '相生').order(:supplier_number)
    end
  end

  def set_supply_variables
    fetch_cached_suppliers
    @supplier_numbers = @sakoshi_suppliers.pluck(:id).map(&:to_s)
    @supplier_numbers += @aioi_suppliers.pluck(:id).map(&:to_s)
    @types = %w[large small eggy damaged large_shells small_shells thin_shells
                small_triploid_shells triploid_shells large_triploid_shells xl_triploid_shells]
  end

  def type_to_japanese(type)
    { 'large' => 'むき身（大）', 'small' => 'むき身（小）', 'eggy' => 'むき身（卵）', 'damaged' => 'むき身（キズ）',
      'large_shells' => '殻付き（大）', 'small_shells' => '殻付き（小）', 'thin_shells' => 'バラ殻付き（kg）',
      'small_triploid_shells' => '殻付き牡蠣（三倍体　M）', 'triploid_shells' => '殻付き牡蠣（三倍体　L）',
      'large_triploid_shells' => '殻付き牡蠣（三倍体　LL）', 'xl_triploid_shells' => '殻付き牡蠣（三倍体　LLL）' }[type]
  end

  def type_to_unit(type)
    { 'large' => 'kg', 'small' => 'kg', 'eggy' => 'kg', 'damaged' => 'kg', 'large_shells' => '個',
      'small_shells' => '個', 'thin_shells' => 'kg', 'small_triploid_shells' => '個',
      'triploid_shells' => '個', 'large_triploid_shells' => '個', 'xl_triploid_shells' => '個' }[type]
  end

  def yenify(number, unit: '', delimiter: ',')
    ActionController::Base.helpers.number_to_currency(number, locale: :ja, unit: unit, delimiter: delimiter)
  end
end
