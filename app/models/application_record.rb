class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  include ApplicationHelper

  def yenify(number)
    ActionController::Base.helpers.number_to_currency(number, locale: :ja, unit: '')
  end

  def yenify_with_decimal(number)
    ActionController::Base.helpers.number_to_currency(number, locale: :ja, unit: '', precision: 1)
  end

  def sales_date_to_datetime
    DateTime.strptime(sales_date, '%Y年%m月%d日')
  end

  def manufacture_date_to_datetime
    DateTime.strptime(manufacture_date, '%Y年%m月%d日')
  end

  def from_nengapi(date)
    Date.strptime(date, '%Y年%m月%d日')
  end

  def to_nengapi(datetime)
    datetime.strftime('%Y年%m月%d日')
  end

  def current_season_upto(datetime)
    # Return array of dates between the start of the returned record's season and the date of the record
    start = datetime.month < 10 ? DateTime.new((datetime.year - 1), 10, 1) : DateTime.new(datetime.year, 10, 1)
    (start..datetime).map { |d| to_nengapi(d) }
  end

  def shipping_cost_hash
    {
      %w[北海道] => { 60 => 1540, 80 => 1740, 100 => 1940 },
      %w[青森県 岩手県 秋田県] => { 60 => 900, 80 => 900, 100 => 900 },
      %w[山形県 宮城県 福島県] => { 60 => 800, 80 => 800, 100 => 800 },
      %w[茨城県 栃木県 群馬県 山梨県 埼玉県 千葉県 東京都 神奈川県] => { 60 => 700, 80 => 700, 100 => 700 },
      %w[新潟県 長野県] => { 60 => 700, 80 => 700, 100 => 700 },
      %w[富山県 石川県 福井県] => { 60 => 600, 80 => 600, 100 => 600 },
      %w[岐阜県 静岡県 愛知県 三重県] => { 60 => 600, 80 => 600, 100 => 600 },
      %w[滋賀県 京都府 大阪府 兵庫県 奈良県 和歌山県] => { 60 => 600, 80 => 600, 100 => 600 },
      %w[鳥取県 島根県 岡山県 広島県 山口県] => { 60 => 600, 80 => 600, 100 => 600 },
      %w[徳島県 香川県 愛媛県 高知県] => { 60 => 600, 80 => 600, 100 => 600 },
      %w[福岡県 佐賀県 長崎県 熊本県 大分県 宮崎県 鹿児島県] => { 60 => 700, 80 => 700, 100 => 700 },
      %w[沖縄県] => { 60 => 1240, 80 => 1740, 100 => 2240 }
    }
  end

  def calculate_shipping(prefecture, box_size)
    return 0 unless [60, 80, 100].include?(box_size)

    shipping = 0
    calculated_shipping = shipping_cost_hash.map do |pref_keys, val_hash|
      val_hash[box_size.to_i] if pref_keys.include?(prefecture)
    end
    shipping += calculated_shipping.compact.sum
    shipping += box_size == 100 ? 300 : 200 # Cool shipping
    shipping
  end

  def hard_coded_costs(mukimi_avg_cost, shell_avg_cost)
    # Hard coding a lot of the raw material cost estimates.
    # Shufunomise anago is about 4600
    # Return the following hash:
    { nama_muki: mukimi_avg_cost, # Cost per 500g
      nama_kara: shell_avg_cost, # Cost per sehll
      p_muki: 500, # Cost per 500g
      p_kara: 50, # Cost per shell
      anago: 6000, # Cost per kilo
      mebi: 4600, # Cost per kilo
      kebi: 2200, # Cost per kilo
      tako: 2200, # Cost per kilo
      bara: 400, # Cost per kilo
      salmon: 800, # Cost per filet
      oyster38: 700, # Cost per bottle
      tsukudani: 175,
      triploid: 70 } # Cost per pack
  end

  def raw_oyster_costs(date)
    Rails.cache.fetch("#{cache_key_with_version}/raw_oyster_costs_#{date}", expires_in: 11.hours) do
      # Need to add a date column to oyster supply with a real date...
      supply = OysterSupply.find_by(date:)
      # By kilo so divide by 2 for 500g packs
      mukimi_avg_cost = supply ? (supply.totals[:sakoshi_avg_kilo] / 2).to_i : 1000
      shell_avg_cost = supply ? supply.totals[:big_shell_avg_cost].to_i : 50
      # Minimum for incomplete supplies
      mukimi_avg_cost = 700 if mukimi_avg_cost < 700
      shell_avg_cost = 45 if shell_avg_cost < 45

      hard_coded_costs(mukimi_avg_cost, shell_avg_cost)
    end
  end
end
