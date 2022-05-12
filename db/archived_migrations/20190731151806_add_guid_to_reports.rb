class AddGuidToReports < ActiveRecord::Migration[5.0]
  def change
    add_column :reports, :guid, :varchar, limit: 40
  end
end
