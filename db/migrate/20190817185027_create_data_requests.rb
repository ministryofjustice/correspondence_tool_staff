class CreateDataRequests < ActiveRecord::Migration[5.0]
  def up
    create_table :data_requests do |t|
      t.references :case, null: false, foreign_key: true, index: true
      t.references :user, null: false # Creator for this request

      t.string :location, null: false, length: 500
      t.text :data,  null: false
      t.date :date_requested, null: false
      t.date :cached_date_received, null: true
      t.integer :cached_num_pages, default: 0, null: false
      t.timestamps
    end

    # Assume the value of +num_pages+ is the current total number of pages
    create_table :data_request_logs do |t|
      t.references :data_request, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true # Creator for this log entry

      t.date :date_received, null: false
      t.integer :num_pages, null: false
      t.timestamps
    end

    add_index :data_requests, [:case_id, :user_id]
    add_index :data_request_logs, [:data_request_id, :user_id]
  end

  def down
    drop_table :data_requests
    drop_table :data_request_logs
  end
end
