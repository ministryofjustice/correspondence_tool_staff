class DropSearchIndexTable < ActiveRecord::Migration[5.0]
  def up
    drop_table :search_index
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Unable to reverse data migration to drop table search_index"
  end

end
