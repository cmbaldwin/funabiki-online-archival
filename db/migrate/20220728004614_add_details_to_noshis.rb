class AddDetailsToNoshis < ActiveRecord::Migration[6.1]
  def change
    change_table :noshis, bulk: true do |t|
      t.string :paper_size
      t.integer :font_size
      t.integer :omotegaki_size
      t.decimal :omotegaki_margin_top
      t.decimal :names_margin_top
    end
  end
end
