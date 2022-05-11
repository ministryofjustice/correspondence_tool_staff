class AddDeletedAtToTeams < ActiveRecord::Migration[5.0]
  def change
    add_column :teams, :deleted_at, :datetime, default: nil
  end
end
