class CreateOroshiBuyer < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_buyers do |t|
      t.string :name, null: false
      t.integer :entity_type, null: false
      t.string :handle, null: false
      t.string :representative_phone
      t.string :fax
      t.string :associated_system_id
      t.string :color
      t.float :handling_cost, null: false
      t.string :handling_cost_notes
      t.float :daily_cost, null: false
      t.string :daily_cost_notes
      t.float :optional_cost, null: false
      t.string :optional_cost_notes
      t.decimal :commission_percentage, null: false
      t.boolean :brokerage, default: true
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
