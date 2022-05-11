class AddPropertiesToReport < ActiveRecord::Migration[5.2]
  def change
    add_column :reports, :properties, :jsonb
  end
end
