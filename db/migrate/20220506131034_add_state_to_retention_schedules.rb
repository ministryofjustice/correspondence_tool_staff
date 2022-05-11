class AddStateToRetentionSchedules < ActiveRecord::Migration[6.1]
  def up
    remove_column :retention_schedules, :status

    execute <<-SQL
      DROP TYPE retention_status;
    SQL

    add_column :retention_schedules, :state, :string
  end

  def down
    remove_column :retention_schedules, :state

    execute <<-SQL
      CREATE TYPE retention_status AS ENUM ('review', 'retain', 'erasable', 'erased', 'not_set');
    SQL
    add_column :retention_schedules, :status, :retention_status
  end
end
