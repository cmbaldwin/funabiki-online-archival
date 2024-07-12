class ExpirationRegenerationWorker
  include Sidekiq::Worker

  def perform(message_id = nil)
    message = Message.find(message_id) if message_id
    # Destroy cards from prior day
    ExpirationCard.where(manufactuered_date: [nengapi_maker(today, -1), '']).destroy_all

    creation_strings.each do |str|
      create_card(str)
    end

    message&.update(state: true, message: 'セルカード作成完了。')

    @card = nil
    GC.start
  end

  def creation_strings
    %w[sakoshi_expiration_today sakoshi_expiration_today_five
       sakoshi_expiration_tomorrow sakoshi_expiration_tomorrow_five
       sakoshi_expiration_today_five_expo sakoshi_expiration_muji
       sakoshi_expiration_frozen sakoshi_triploid_expiration_today
       aioi_expiration_today aioi_expiration_today_five aioi_expiration_tomorrow
       aioi_expiration_tomorrow_five aioi_expiration_today_five_expo
       aioi_expiration_muji aioi_expiration_frozen]
  end

  def create_card(str)
    @card = ExpirationCard.new(**send("#{str}_config"))
    @card.create_pdf
  end

  def nengapi_maker(date, adjust)
    (date + adjust).strftime('%Y年%m月%d日')
  end

  def today
    Time.zone.today
  end

  def sakoshi_expiration_today_config
    { product_name:,
      manufacturer_address:,
      manufacturer:,
      ingredient_source: sakoshi,
      consumption_restrictions: raw,
      manufactuered_date: nengapi_maker(today, 0),
      expiration_date: nengapi_maker(today, 4),
      storage_recommendation: fridge,
      made_on: true, shomiorhi: true }
  end

  def sakoshi_expiration_today_five_config
    { product_name:,
      manufacturer_address:,
      manufacturer:,
      ingredient_source: sakoshi,
      consumption_restrictions: raw,
      manufactuered_date: nengapi_maker(today, 0),
      expiration_date: nengapi_maker(today, 5),
      storage_recommendation: fridge,
      made_on: true,
      shomiorhi: true }
  end

  def sakoshi_expiration_tomorrow_config
    { product_name:,
      manufacturer_address:,
      manufacturer:,
      ingredient_source: sakoshi,
      consumption_restrictions: raw,
      manufactuered_date: nengapi_maker(today, 1),
      expiration_date: nengapi_maker(today, 5),
      storage_recommendation: fridge,
      made_on: true, shomiorhi: true }
  end

  def sakoshi_expiration_tomorrow_five_config
    { product_name:,
      manufacturer_address:,
      manufacturer:,
      ingredient_source: sakoshi,
      consumption_restrictions: raw,
      manufactuered_date: nengapi_maker(today, 1),
      expiration_date: nengapi_maker(today, 6),
      storage_recommendation: fridge,
      made_on: true,
      shomiorhi: true }
  end

  def sakoshi_expiration_today_five_expo_config
    { product_name:,
      manufacturer_address:,
      manufacturer:,
      ingredient_source: sakoshi,
      consumption_restrictions: raw,
      manufactuered_date: nengapi_maker(today, 0),
      expiration_date: nengapi_maker(today, 5),
      storage_recommendation: fridge,
      made_on: false,
      shomiorhi: true }
  end

  def sakoshi_expiration_muji_config
    { product_name:,
      manufacturer_address:,
      manufacturer:,
      ingredient_source: sakoshi,
      consumption_restrictions: raw,
      manufactuered_date: '',
      expiration_date: '',
      storage_recommendation: fridge,
      made_on: true,
      shomiorhi: true }
  end

  def sakoshi_expiration_frozen_config
    { product_name: '冷凍殻付き牡蠣（プロトン凍結）',
      manufacturer_address:,
      manufacturer:,
      ingredient_source: sakoshi,
      consumption_restrictions: '加熱調理用',
      manufactuered_date: nengapi_maker(today, 0),
      expiration_date: (today + 23.months).strftime('%Y年%m月'),
      storage_recommendation: '	ー１８℃以下保存',
      made_on: false,
      shomiorhi: false }
  end

  def sakoshi_triploid_expiration_today_config
    { product_name: '殻付き かき（三倍体）',
      manufacturer_address:,
      manufacturer:,
      ingredient_source: sakoshi,
      consumption_restrictions: raw,
      manufactuered_date: nengapi_maker(today, 0),
      expiration_date: nengapi_maker(today, 4),
      storage_recommendation: fridge,
      made_on: true,
      shomiorhi: false }
  end

  def aioi_expiration_today_config
    { product_name:,
      manufacturer_address:,
      manufacturer:,
      ingredient_source: aioi,
      consumption_restrictions: raw,
      manufactuered_date: nengapi_maker(today, 0),
      expiration_date: nengapi_maker(today, 4),
      storage_recommendation: fridge,
      made_on: true,
      shomiorhi: true }
  end

  def aioi_expiration_today_five_config
    { product_name:,
      manufacturer_address:,
      manufacturer:,
      ingredient_source: aioi,
      consumption_restrictions: raw,
      manufactuered_date: nengapi_maker(today, 0),
      expiration_date: nengapi_maker(today, 5),
      storage_recommendation: fridge,
      made_on: true,
      shomiorhi: true }
  end

  def aioi_expiration_tomorrow_config
    { product_name:,
      manufacturer_address:,
      manufacturer:,
      ingredient_source: aioi,
      consumption_restrictions: raw,
      manufactuered_date: nengapi_maker(today, 1),
      expiration_date: nengapi_maker(today, 5),
      storage_recommendation: fridge,
      made_on: true,
      shomiorhi: true }
  end

  def aioi_expiration_tomorrow_five_config
    { product_name:,
      manufacturer_address:,
      manufacturer:,
      ingredient_source: aioi,
      consumption_restrictions: raw,
      manufactuered_date: nengapi_maker(today, 1),
      expiration_date: nengapi_maker(today, 6),
      storage_recommendation: fridge,
      made_on: true,
      shomiorhi: true }
  end

  def aioi_expiration_today_five_expo_config
    { product_name:,
      manufacturer_address:,
      manufacturer:,
      ingredient_source: aioi,
      consumption_restrictions: raw,
      manufactuered_date: nengapi_maker(today, 0),
      expiration_date: nengapi_maker(today, 5),
      storage_recommendation: fridge,
      made_on: false,
      shomiorhi: true }
  end

  def aioi_expiration_muji_config
    { product_name:,
      manufacturer_address:,
      manufacturer:,
      ingredient_source: aioi,
      consumption_restrictions: raw,
      manufactuered_date: '',
      expiration_date: '',
      storage_recommendation: fridge,
      made_on: true,
      shomiorhi: true }
  end

  def aioi_expiration_frozen_config
    { product_name: '冷凍殻付き牡蠣（プロトン凍結）',
      manufacturer_address:,
      manufacturer:,
      ingredient_source: aioi,
      consumption_restrictions: '加熱調理用',
      manufactuered_date: nengapi_maker(today, 0),
      expiration_date: (today + 23.months).strftime('%Y年%m月'),
      storage_recommendation: '	ー１８℃以下保存',
      made_on: false,
      shomiorhi: false }
  end

  def product_name
    '殻付き かき'
  end

  def manufacturer_address
    '兵庫県赤穂市中広1576-11'
  end

  def manufacturer
    '株式会社 船曳商店'
  end

  def sakoshi
    '兵庫県坂越海域'
  end

  def aioi
    '兵庫県相生海域'
  end

  def raw
    '生食用'
  end

  def fridge
    '要冷蔵　0℃～10℃'
  end
end
