class ChangeRequestTypeColumnType < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      UPDATE data_requests SET request_type = 'other';
      CREATE TYPE request_types AS ENUM ('offender', 'all_prison_records', 'all_nomis_records', 'nomis_contact_logs', 'probation_records', 'prison_and_probation_records', 'other');
      ALTER TABLE data_requests ALTER COLUMN request_type TYPE request_types USING request_type::request_types;
    SQL
  end

  def down
    change_column :data_requests, :request_type, :text
    execute <<-SQL
      DROP TYPE request_types;
    SQL
  end
end
