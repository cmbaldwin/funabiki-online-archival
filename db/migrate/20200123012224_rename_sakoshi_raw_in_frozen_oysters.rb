class RenameSakoshiRawInFrozenOysters < ActiveRecord::Migration[5.2]
  def change
  	rename_column :frozen_oysters, :sakoshi_raw, :okayama_raw
  end
end
