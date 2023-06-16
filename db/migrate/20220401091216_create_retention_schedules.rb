class CreateRetentionSchedules < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      CREATE TYPE retention_status AS ENUM ('review', 'retain', 'erasable', 'erased', 'not_set');
    SQL

    create_table :retention_schedules do |t|
      t.references :case, null: false, foreign_key: true
      t.date :planned_erasure_date
      t.date :erasure_date
      t.column :status, :retention_status
      t.timestamps
    end
  end

  def down
    drop_table :retention_schedules

    execute <<-SQL
      DROP TYPE retention_status;
    SQL
  end
end
