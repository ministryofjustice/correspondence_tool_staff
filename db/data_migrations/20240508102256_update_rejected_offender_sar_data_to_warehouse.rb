class UpdateRejectedOffenderSARDataToWarehouse < ActiveRecord::DataMigration
  def up
    Case::Base.offender_sar.where("properties ->> 'case_originally_rejected' = 'true'").find_each do |k|
      k.update_attribute(:rejected_reasons, Warehouse::CaseReport.rejected_reasons_selection(k)) unless k.readonly? # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
