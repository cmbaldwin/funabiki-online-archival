module Rakuten
  module Settings
    def shipping_days(prefecture)
      shipping_days_hash = {
        %w[北海道 青森県 岩手県 秋田県] => 2, # 北海道
        %w[山形県 宮城県 福島県] => 1, # 南北
        %w[茨城県 栃木県 群馬県 山梨県 埼玉県 千葉県 東京都 神奈川県] => 1, # 関東
        %w[新潟県 長野県] => 1, # 信越
        %w[富山県 石川県 福井県] => 1, # 北陸
        %w[岐阜県 静岡県 愛知県 三重県] => 1, # 中部
        %w[滋賀県 京都府 大阪府 兵庫県 奈良県 和歌山県] => 1, # 関西
        %w[鳥取県 島根県 岡山県 広島県 山口県] => 1, # 中国
        %w[徳島県 香川県 愛媛県 高知県] => 1, # 四国
        %w[福岡県 佐賀県 熊本県 大分県 宮崎県] => 1, # 九州
        %w[長崎県 鹿児島県 沖縄県] => 2 # 九州・沖縄
      }
      shipping_days_hash.each { |pref_arr, new_days| return new_days if pref_arr.include?(prefecture) }
      1 # Default value
    end

    def enum_arrival_times(integer)
      { '午前中' => 0,
        '14:00-16:00' => 1,
        '18:00-20:00' => 2 }[integer]
    end

    def earliest_arrival(prefecture, city)
      # {"prefecture" => { "city" => [days_to_arrival_integer, time_on_that_day_integer] } }
      # used with:
      # def add_hours_enum(integer)
      #   {
      #     0 => 12.hours,
      #     1 => 16.hours,
      #     2 => 18.hours}[integer]
      # end
      arrival_hash = {
        # 北海道
        "北海道" => {
          base: [2, 0],
          "奥尻郡" => [2, 2]
        },
        # 北南北
        "青森県" => { base: [2, 0] },
        "岩手県" => { base: [2, 0] },
        "秋田県" => { base: [2, 0] },
        # 南東北
        "宮城県" => { base: [1, 1] },
        "山形県" => {
          base: [1, 2],
          "上山市" => [1, 1],
          "寒河江市" => [1, 1],
          "天童市" => [1, 1],
          "東根市" => [1, 1],
          "村山市" => [1, 1],
          "山形市" => [1, 1]
        },
        "福島県" => { base: [1, 2],
                   "会津若松市" => [1, 1],
                   "安達郡" => [1, 1],
                   "大沼郡" => [1, 1],
                   "河沼郡" => [1, 1],
                   "喜多方市" => [1, 1],
                   "郡山市" => [1, 1],
                   "伊達郡" => [1, 1],
                   "伊達市" => [1, 1],
                   "二本松市" => [1, 1],
                   "福島市" => [1, 1],
                   "本宮市" => [1, 1],
                   "耶麻市" => [1, 1] },
        # 関東
        "茨城県" => { base: [1, 1] },
        "栃木県" => { base: [1, 1] },
        "群馬県" => {
          base: [1, 1],
          "吾妻郡" => [1, 2]
        },
        "埼玉県" => { base: [1, 0] },
        "千葉県" => { base: [1, 0] },
        "神奈川県" => { base: [1, 0] },
        "東京都" => { base: [1, 0] },
        "山梨県" => { base: [1, 0] },
        # 信越
        "新潟県" => { base: [1, 1] },
        "長野県" => { base: [1, 0] },
        # 北陸
        "富山県" => { base: [1, 0] },
        "石川県" => { base: [1, 0] },
        "福井県" => { base: [1, 0] },
        # 中部
        "岐阜県" => { base: [1, 0] },
        "静岡県" => { base: [1, 0] },
        "愛知県" => { base: [1, 0] },
        "三重県" => { base: [1, 0] },
        # 関西
        "滋賀県" => { base: [1, 0] },
        "京都府" => { base: [1, 0] },
        "大阪府" => { base: [1, 0] },
        "兵庫県" => { base: [1, 0] },
        "奈良県" => { base: [1, 0] },
        "和歌山県" => { base: [1, 0] },
        # 中国
        "鳥取県" => { base: [1, 0] },
        "島根県" => {
          base: [1, 0],
          "隠岐郡" => [1, 1]
        },
        "岡山県" => { base: [1, 0] },
        "広島県" => { base: [1, 0] },
        "山口県" => { base: [1, 0] },
        # 四国
        "徳島県" => { base: [1, 0] },
        "香川県" => { base: [1, 0] },
        "愛媛県" => { base: [1, 0] },
        "高知県" => { base: [1, 0] },
        # 九州
        "福岡県" => { base: [1, 0] },
        "佐賀県" => { base: [1, 1] },
        "長崎県" => {
          base: [1, 1],
          "小値賀島" => [2, 2],
          "五島市" => [2, 2],
          "対馬市" => [2, 0],
          "南松浦郡" => [2, 2]
        },
        "熊本県" => {
          base: [1, 1],
          "天草郡" => [1, 2],
          "天草市" => [1, 2]
        },
        "大分県" => {
          base: [1, 1],
          "中津市" => [1, 0]
        },
        "宮崎県" => { base: [1, 1] },
        "鹿児島県" => {
          base: [1, 1],
          "奄美市" => [2, 0],
          "大島郡" => [2, 1],
          "大島郡龍郷町" => [2, 0],
          "熊毛郡南種子町" => [2, 2],
          "熊毛郡" => [2, 2],
          "熊西之表市" => [2, 2]
        },
        # 沖縄県
        "沖縄県" => {
          base: [2, 0],
          "石垣市" => [2, 2],
          "島尻郡" => [2, 1],
          "宮古島市" => [2, 2]
        }

      }
      if arrival_hash.keys.include?(prefecture)
        if arrival_hash[prefecture].keys.include?(city)
          arrival_hash[prefecture][city]
        else
          arrival_hash[prefecture][:base]
        end
      else
        @errors << ["Error: no pref or city keys found #{[prefecture, city]}, for order: #{@id}"]
        [1, 0]
      end
    end

    def add_hours_enum(integer)
    {
      0 => 12.hours,
      1 => 16.hours,
      2 => 18.hours
    }[integer]
    end

    def add_hours_string(string)
    {
      '午前中' => 12.hours,
      '14:00-16:00' => 16.hours,
      '16:00-18:00' => 18.hours,
      '18:00-20:00' => 20.hours,
      '19:00-21:00' => 21.hours,
      0 => 21.hours,
      1 => 12.hours,
      2 => 21.hours,
      1416 => 16.hours,
      1618 => 18.hours,
      1820 => 20.hours,
      1921 => 21.hours
    }[string]
    end

    def ec_product_cache
      Rails.cache.fetch('ec_products_cache') do
        EcProduct.all
      end || EcProduct.all
    end

    def query_product_attribute(item_id, attribute)
       ec_product_cache.with_reference_id(item_id)&.first.try(attribute)
    end

    def item_frozen?(item_id)
      # Defaults to refrigerated if not specified
      query_product_attribute(item_id, 'frozen_item') || false
    end

    def memo_product_name(item_id)
      query_product_attribute(item_id, 'memo_name') || '???'
    end

    def simple_item_name(item_id)
      Rails.cache.fetch("#{item_id}_rakuten_automation_simple_name", expires_in: 5.minutes) do
        query_product_attribute(item_id, 'name') || '???'
      end
    end

    def get_extra_cost(prefecture, item_id)
      item_extra_cost = query_product_attribute(item_id, 'extra_shipping_cost') || 0

      %w[北海道 青森県 岩手県 秋田県 沖縄県].include?(prefecture) ? item_extra_cost : 0
    end
  end
end
