class CreateSystemLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :system_logs do |t|
      t.string :type, null: false, index: true
      t.string :status, default: "pending"
      t.string :reference_id, index: true
      t.string :action
      t.string :source
      t.jsonb :metadata, default: {}
      t.text :error_message
      t.float :duration_ms
      t.datetime :completed_at
      t.timestamps
    end

    add_index :system_logs, :created_at
    add_index :system_logs, %i[type status]
  end
end
