class UpdateDataRequestsRequestTypes < ActiveRecord::DataMigration
  def up
    # The first execute was a DB migration (db/migrate) and since we've archived old migrations,
    # it is not run, but the second execute assumes it has been run. So as a workaround, we
    # unify both migrations in this one file so that the `db:reseed` can complete successfully.
    #
    execute <<-SQL
      UPDATE data_requests SET request_type = 'all_prison_records';
      CREATE TYPE request_types_enum AS ENUM ('all_prison_records', 'security_records', 'nomis_records', 'nomis_contact_logs', 'probation_records', 'prison_and_probation_records', 'other');
      ALTER TABLE data_requests ALTER COLUMN request_type TYPE request_types_enum USING request_type::text::request_types_enum;
      DROP TYPE request_types;
    SQL

    execute <<-SQL
      UPDATE data_requests SET request_type = 'other', request_type_note='prison_and_probation_records' where id in (select id from data_requests where request_type='prison_and_probation_records');
      CREATE TYPE request_types AS ENUM ('all_prison_records', 'security_records', 'nomis_records', 'nomis_other', 'nomis_contact_logs', 'probation_records', 'cctv_and_bwcf', 'telephone_recordings', 'telephone_pin_logs', 'probation_archive', 'mappa', 'pdp', 'court', 'other');
      ALTER TABLE data_requests ALTER COLUMN request_type TYPE request_types USING request_type::text::request_types;
      DROP TYPE request_types_enum;
    SQL
  end
end
