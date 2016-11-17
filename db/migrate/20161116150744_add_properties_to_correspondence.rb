class AddPropertiesToCorrespondence < ActiveRecord::Migration[5.0]
  def change
    add_column :correspondence, :properties, :jsonb
  end
end
