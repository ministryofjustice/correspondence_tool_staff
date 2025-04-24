class AddDpsMissingDataToCases < ActiveRecord::Migration[7.2]
  def change
    add_column :cases, :dps_missing_data, :boolean
  end
end
