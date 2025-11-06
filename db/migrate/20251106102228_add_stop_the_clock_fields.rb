class AddStopTheClockFields < ActiveRecord::Migration[7.2]
  def change
    add_column :cases, :stop_at, :datetime
    add_column :cases, :stop_reason, :string
    add_column :cases, :stop_by, :integer
  end
end
