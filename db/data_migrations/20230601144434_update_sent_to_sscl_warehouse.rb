class UpdateSentToSsclWarehouse < ActiveRecord::DataMigration
  def up
    execute <<-SQL
      UPDATE warehouse_case_reports wcr
      SET sent_to_sscl = date(properties->>'sent_to_sscl_at')
      FROM cases c
      WHERE wcr.case_id = c.id;
    SQL
  end
end
