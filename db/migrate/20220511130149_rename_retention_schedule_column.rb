class RenameRetentionScheduleColumn < ActiveRecord::Migration[6.1]
  def up
    rename_column :retention_schedules, :planned_erasure_date, :planned_destruction_date
  end

  def down
    rename_column :retention_schedules, :planned_destruction_date, :planned_erasure_date
  end
end
