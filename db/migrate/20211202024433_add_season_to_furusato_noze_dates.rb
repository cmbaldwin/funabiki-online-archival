class AddSeasonToFurusatoNozeDates < ActiveRecord::Migration[6.1]
  def change
    add_column :furusato_noze_dates, :season, :text
  end
end
