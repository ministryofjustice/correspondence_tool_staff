class UpdateRejectedOffenderSARDataToWarehouse < ActiveRecord::Migration[7.1]
  def up
    Case::Base.offender_sar.where("properties ->> 'case_originally_rejected' = 'true'").find_each do |k|
      k.update_attribute(:rejected_reasons, Warehouse::CaseReport.rejected_reasons_selection(k)) unless k.readonly? # rubocop:disable Rails/SkipsModelValidations
    end

    execute <<-SQL
      UPDATE warehouse_case_reports wcr
      SET case_originally_rejected = properties->>'case_originally_rejected'
      FROM cases c
      WHERE wcr.case_id = c.id;
    SQL

    execute <<-SQL
      UPDATE warehouse_case_reports wcr
      SET rejected = rejected
      FROM cases c
      WHERE wcr.case_id = c.id;
    SQL

    execute <<-SQL
      UPDATE warehouse_case_reports wcr
      SET other_rejected_reason = properties->>'other_rejected_reason'
      FROM cases c
      WHERE wcr.case_id = c.id;
    SQL
  end
end
