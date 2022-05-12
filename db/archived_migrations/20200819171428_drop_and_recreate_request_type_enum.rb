class DropAndRecreateRequestTypeEnum < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      UPDATE data_requests SET request_type = 'all_prison_records';
      CREATE TYPE request_types_enum AS ENUM ('all_prison_records', 'security_records', 'nomis_records', 'nomis_contact_logs', 'probation_records', 'prison_and_probation_records', 'other');
      ALTER TABLE data_requests ALTER COLUMN request_type TYPE request_types_enum USING request_type::text::request_types_enum;
      DROP TYPE request_types;
    SQL
  end

  def down
    change_column :data_requests, :request_type, :text
    execute <<-SQL
      DROP TYPE request_types_enum;
    SQL
  end
end
