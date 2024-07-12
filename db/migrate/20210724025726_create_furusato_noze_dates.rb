class CreateFurusatoNozeDates < ActiveRecord::Migration[6.1]
  def change
    create_table :furusato_noze_dates do |t|
      t.date :date
      t.text :data
      t.timestamps
    end   
    add_reference :furusato_noze_dates, :stat, index: true
  end
end
