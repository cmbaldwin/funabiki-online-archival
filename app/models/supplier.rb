class Supplier < ApplicationRecord
  enum location: %I[\u5742\u8D8A \u76F8\u751F \u7389\u6D25 \u9091\u4E45 \u4F0A\u91CC \u65E5\u751F]
  after_initialize :set_default_location, if: :new_record?
  def set_default_location
    self.location ||= :坂越
  end

  validates_presence_of :company_name
  validates_uniqueness_of :company_name

  def nickname
    nick = company_name
    ['有限', '株式', '会社'].each { |str| nick.gsub!(str, '') }
    nick
  end
end
