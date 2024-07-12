class DropCkeditorAssets < ActiveRecord::Migration[5.2]
  def change
  	drop_table :ckeditor_assets
  end
end
