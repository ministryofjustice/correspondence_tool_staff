class CreateDataRequests < ActiveRecord::Migration[5.0]
  def up
    create_table :data_requests do |t|
      t.references :case, null: false
      t.references :user, null: false # Creator for this request

      t.string :location, null: false, length: 500
      t.text :data,  null: false
      t.date :date_requested, null: false, default: Date.current
      t.timestamps
    end

    add_index :data_requests, [:case_id, :user_id]
  end

  def down
    drop_table :data_requests
  end
end
