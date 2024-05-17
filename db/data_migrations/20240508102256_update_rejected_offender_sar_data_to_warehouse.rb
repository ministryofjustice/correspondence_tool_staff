class UpdateRejectedOffenderSARDataToWarehouse < ActiveRecord::DataMigration
  def up
    Case::Base.offender_sar.where("properties ->> 'case_originally_rejected' = 'true'").find_each do |k|
      k.touch unless k.readonly?
    end
  end
end
