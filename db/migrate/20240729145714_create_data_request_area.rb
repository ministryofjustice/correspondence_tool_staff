class CreateDataRequestArea < ActiveRecord::Migration[7.1]
  def up
    create_enum :data_request_area_type, %w[prison probation branston branston_registry mappa]

    create_table :data_request_areas do |t|
      t.belongs_to :case
      t.string :area_type
      t.enum :data_request_area_type, enum_type: "data_request_area_type", null: false
    end
  end

  def down
    drop_table :data_request_areas
    drop_enum :data_request_area_type
  end
end
