class CreateDataRequestArea < ActiveRecord::Migration[7.1]
  def up
    create_enum :data_request_area_type, %w[prison probation branston branston_registry mappa]

    create_table :data_request_areas do |t|
      t.references :case, null: false, foreign_key: true, index: true
      t.references :user, null: false
      t.references :contact, null: true, foreign_key: true

      t.enum :data_request_area_type, enum_type: "data_request_area_type", null: false

      t.integer :cached_num_pages, default: 0
      t.integer :num_of_requests, default: 0
      t.boolean :completed, default: false
      t.date :date_requested
      t.date :cached_date_received, null: true
      t.date :date_from, null: true
      t.date :date_to, null: true
      t.string :location
      t.timestamps
    end
  end

  def down
    drop_table :data_request_areas
    drop_enum :data_request_area_type
  end
end
