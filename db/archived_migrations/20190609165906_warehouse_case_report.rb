# Denormalised data-warehousing of all case data required to generate
# Open/Closed reports. There is a one-to-one relationship between
# this warehouse table and the cases table.
class WarehouseCaseReport < ActiveRecord::Migration[5.0]

  # Copied from CSVExporter::CSV_COLUMN_HEADINGS (July 2019)
  REPORT_FIELDS = {
    'Number' => :string,
    'Case type' => :string,
    'Current state' => :string,
    'Responding team' => :string,
    'Responder' => :string,
    'Date received' => :date,
    'Internal deadline' => :date,
    'External deadline' => :date,
    'Date responded' => :date,
    'Date compliant draft uploaded' => :date,
    'Trigger' => :string,
    'Name' => :string,
    'Requester type' => :string,
    'Message' => :string,
    'Info held' => :string,
    'Outcome' => :string,
    'Refusal reason' => :string,
    'Exemptions' => :string,
    'Postal address' => :string,
    'Email' => :string,
    'Appeal outcome' => :string,
    'Third party' => :string,
    'Reply method' => :string,
    'SAR Subject type' => :string,
    'SAR Subject full name' => :string,
    'Business unit responsible for late response' => :string,
    'Extended' => :string,
    'Extension count' => :integer,
    'Deletion reason' => :string,
    'Casework officer' => :string,
    'Created by' => :string,
    'Date created' => :datetime,
    'Business group' => :string,
    'Directorate name' => :string,
    'Director General name' => :string,
    'Director name' => :string,
    'Deputy Director name' => :string,
    'Draft in time' => :string,
    'In target' => :string,
    'Number of days late' => :integer,
  }.freeze

  def up
    create_table :warehouse_case_reports, id: false do |t|
      t.references :case, primary_key: true, foreign_key: true, null: false, index: true
      t.timestamps

      t.column :creator_id, :integer
      t.column :responding_team_id, :integer
      t.column :responder_id, :integer
      t.column :casework_officer_user_id, :integer
      t.column :business_group_id, :integer
      t.column :directorate_id, :integer
      t.column :director_general_name_property_id, :integer
      t.column :director_name_property_id, :integer
      t.column :deputy_director_name_property_id, :integer

      REPORT_FIELDS.each do |field, col_type|
        t.column field.parameterize.underscore, col_type, null: true
      end
    end
  end

  def down
    drop_table :warehouse_case_reports
  end
end
