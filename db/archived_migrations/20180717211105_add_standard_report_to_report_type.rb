class AddStandardReportToReportType < ActiveRecord::Migration[5.0]
  require Rails.root.join("db/seeders/report_type_seeder")

  # rubocop:disable Rails/ReversibleMigration
  def change
    add_column :report_types, :standard_report, :boolean, default: false
    change_column :report_types, :standard_report, :boolean, null: false
    add_column :report_types, :default_reporting_period, :string, default: "year_to_date"
  end
  # rubocop:enable Rails/ReversibleMigration
end
