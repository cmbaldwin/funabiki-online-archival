class CreateOroshiOrderTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_order_templates do |t|
      t.references :order, null: false, foreign_key: { to_table: :oroshi_orders }
      t.text :notes
      t.string :identifier
      t.timestamps
    end
  end
end
