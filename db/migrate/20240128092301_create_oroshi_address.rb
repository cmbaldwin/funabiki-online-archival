class CreateOroshiAddress < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_addresses do |t|
      t.string :name
      t.string :company
      t.string :address1
      t.string :address2
      t.string :city
      t.string :postal_code
      t.string :phone
      t.string :alternative_phone
      t.integer :subregion_id
      t.integer :country_id
      t.boolean :default, default: false
      t.boolean :active, default: true
      t.references :addressable, polymorphic: true, null: false
      t.timestamps
    end
  end
end
