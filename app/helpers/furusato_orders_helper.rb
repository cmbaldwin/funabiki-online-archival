module FurusatoOrdersHelper
  def counts(orders)
    orders.all.map(&:count).transpose.map(&:sum)
  end

  def furusato_count_header(i)
    ['生むき身','生殻付き','セルカード','冷凍むき身','冷凍殻付き','焼き穴子','干しエビ（ムキ）','干しエビ（殻）','ボイルたこ','バラ殻付き','サーモン','オイスターソース','サムライ佃煮'][i]
  end

  def furusato_count_counter(i)
    ['枚', '個', '枚', 'パック', '個','g','パック（100g）','パック（100g）','件','個','件','本','パック'][i]
  end
end
