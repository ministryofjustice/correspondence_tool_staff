class DropDataRequestLogs < ActiveRecord::Migration[6.1]
  def up
    drop_table :data_request_logs
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
