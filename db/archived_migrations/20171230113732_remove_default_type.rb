class RemoveDefaultType < ActiveRecord::Migration[5.0]
  def change
    change_column_default(:cases, :type, nil)
  end
end
