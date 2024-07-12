class RemoveCommenterFromComments < ActiveRecord::Migration[5.2]
  def change
    remove_column :comments, :commenter, :string
    add_column :comments, :title, :string
  end
end
