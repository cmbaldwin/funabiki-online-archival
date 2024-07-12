class DropNoshis < ActiveRecord::Migration[6.1]
  def up
    drop_table :noshis
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
