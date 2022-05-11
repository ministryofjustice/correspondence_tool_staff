class ChangeColumnName < ActiveRecord::Migration[5.0]
  def change
    rename_column :cases, :deleted?, :deleted
  end
end
