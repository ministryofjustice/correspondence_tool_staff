class RectifyCaseSubjectTypeValues < ActiveRecord::DataMigration
  def up
    # Bug https://dsdmoj.atlassian.net/browse/CT-2428
    # Case.properties ->> 'subject_type' can have 'offender' as a value.
    # Due to an error during refactoring, the value was changed to 'offender_sar'

    Case::Base.connection.execute <<~EOSQL
      UPDATE cases#{' '}
        SET properties = jsonb_set(properties, '{subject_type}', '"offender"', false)#{' '}
        WHERE properties ->> 'subject_type' = 'offender_sar';
    EOSQL

    # Force re-index in separate process
    `cd #{Rails.root}; ./cts cases reindex;`
  end

  def down
    # No change as this repairs an error in data integrity
  end
end
