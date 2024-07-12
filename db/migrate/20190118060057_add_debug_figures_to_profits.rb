class AddDebugFiguresToProfits < ActiveRecord::Migration[5.2]
  def change
    add_column :profits, :debug_figures, :text
  end
end
