class CreateReportsCaches < ActiveRecord::Migration[7.2]
  def change
    create_table :reports_caches do |t|
      t.string :report_type, null: false
      t.jsonb :data, null: false, default: {}
      t.timestamps
    end

    add_index :reports_caches, :report_type
    add_index :reports_caches, :created_at
    add_index :reports_caches, :data, using: :gin

    # Unique constraint to support upsert-by-type of the latest record if desired
    # We won't enforce uniqueness across time, but applications can choose to delete old rows
  end
end
