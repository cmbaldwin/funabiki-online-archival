module SuppliersHelper
  def aioi_secondary(supplier)
    'bg-light' if supplier.location == '相生'
  end

  def tax
    "#{((@oyster_supply.oysters['tax'].to_f - 1) * 100).to_i}%"
  end

  def type_to_kana(type)
    keys = { 'large' => 'むき身（大）', 'small' => 'むき身（小）', 'eggy' => 'むき身（卵）', 'damaged' => 'むき身（傷）',
             'large_shells' => '殻付き〔大-個〕', 'small_shells' => '殻付き〔小-個〕', 'thin_shells' => '殻付き〔バラ-㎏〕', 
             'small_triploid_shells' => '殻付き（三倍体）M', 'triploid_shells' => '殻付き（三倍体）L', 
             'large_triploid_shells' => '殻付き（三倍体）LL', 'xl_triploid_shells' => '殻付き（三倍体）LLL' }
    keys[type]
  end
end
