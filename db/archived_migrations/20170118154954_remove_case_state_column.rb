class RemoveCaseStateColumn < ActiveRecord::Migration[5.0]
  def change
    remove_column :cases, :state
  end
end
