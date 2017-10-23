class AddInfoHeldStatusIdToCase < ActiveRecord::Migration[5.0]
  def change
    add_column :cases, :info_held_status_id, :integer
  end
end
