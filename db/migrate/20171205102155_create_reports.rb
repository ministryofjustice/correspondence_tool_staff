class CreateReports < ActiveRecord::Migration[5.0]
  def change
    create_table :reports do |t|
      t.references :report_type, null: false
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.binary :report_data
    end
  end
end
