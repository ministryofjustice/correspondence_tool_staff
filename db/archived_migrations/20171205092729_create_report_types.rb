class CreateReportTypes < ActiveRecord::Migration[5.0]
  require File.join(Rails.root, 'db', 'seeders', 'report_type_seeder')

  def change
    create_table :report_types do |t|
      t.string :abbr, null: false
      t.string :full_name, null: false
      t.string :class_name, null: false
      t.boolean :custom_report, default: false
      t.integer :seq_id, null: false
    end
    add_index :report_types, :abbr, unique: true
  end
end
