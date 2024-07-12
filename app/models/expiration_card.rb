class ExpirationCard < ApplicationRecord
  has_one_attached :file

  def self.sakoshi_str
    '兵庫県坂越海域'
  end

  def self.aioi_str
    '兵庫県相生海域'
  end

  def self.today
    Time.zone.today
  end

  def self.nengapi_maker(date, plus)
    (date + plus).strftime('%Y年%m月%d日')
  end

  def self.sakoshi_exp_card(man_date_num, exp_day_num, print_made_on: true)
    where(
      ingredient_source: sakoshi_str,
      manufactuered_date: nengapi_maker(today, man_date_num),
      expiration_date: nengapi_maker(today, exp_day_num),
      made_on: print_made_on,
      shomiorhi: true
    ).first
  end

  def self.sakoshi_sanbaitai
    find_by(product_name: '殻付き かき（三倍体）')
  end

  def self.muji(is_sakoshi: true)
    where(
      ingredient_source: is_sakoshi ? sakoshi_str : aioi_str,
      manufactuered_date: '',
      expiration_date: '',
      made_on: true
    ).first
  end

  def self.sakoshi_frozen
    where(
      product_name: '冷凍殻付き牡蠣（プロトン凍結）',
      ingredient_source: sakoshi_str
    ).first
  end

  def self.aioi_exp_card(man_date_num, exp_day_num, print_made_on: true)
    where(
      ingredient_source: aioi_str,
      manufactuered_date: nengapi_maker(today, man_date_num),
      expiration_date: nengapi_maker(today, exp_day_num),
      made_on: print_made_on,
      shomiorhi: true
    ).first
  end

  def self.aioi_frozen
    where(
      product_name: '冷凍殻付き牡蠣（プロトン凍結）',
      ingredient_source: aioi_str
    ).first
  end

  def create_pdf
    save unless id
    pdf = ShellCard.new(id)
    io = StringIO.new pdf.render
    file.attach(io:, content_type: 'application/pdf', filename:)
    save
    pdf = nil
    io = nil
    GC.start
  end

  def filename
    "#{product_name}-#{manufactuered_date}-#{expiration_date}-#{manufactured_only}-カード.pdf"
  end

  def manufactured_only
    made_on ? '（製造日なし）' : ''
  end

  def print_shomiorhi
    shomiorhi ? ' 消    費    期    限' : ' 賞    味    期    限'
  end

  def shomiorhi_string
    shomiorhi ? '消費期限' : '賞味期限'
  end
end
