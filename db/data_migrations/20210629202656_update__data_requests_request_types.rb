class UpdateDataRequestsRequestTypes < ActiveRecord::DataMigration
  def up
    execute <<-SQL
      UPDATE data_requests SET request_type = 'other', request_type_note='prison_and_probation_records' where id in (select id from data_requests where request_type='prison_and_probation_records');
      CREATE TYPE request_types AS ENUM ('all_prison_records', 'security_records', 'nomis_records', 'nomis_other', 'nomis_contact_logs', 'probation_records', 'cctv_and_bwcf', 'telephone_recordings', 'telephone_pin_logs', 'probation_archive', 'mappa', 'pdp', 'court', 'other');
      ALTER TABLE data_requests ALTER COLUMN request_type TYPE request_types USING request_type::text::request_types;
      DROP TYPE request_types_enum;
    SQL
  end
end
