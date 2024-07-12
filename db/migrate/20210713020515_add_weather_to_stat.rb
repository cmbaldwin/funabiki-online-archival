class AddWeatherToStat < ActiveRecord::Migration[6.1]
  def change
    add_column :stats, :weather, :text
  end
end
