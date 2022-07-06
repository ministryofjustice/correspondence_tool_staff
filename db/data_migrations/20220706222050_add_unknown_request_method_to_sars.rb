class AddUnknownRequestMethodToSars < ActiveRecord::DataMigration
  def up
    Case::Base.non_offender_sar.each { |k| k.update_attribute(:request_method, "unknown") }
    Case::Base.offender_sar.each { |k| k.update_attribute(:request_method, "unknown") }
  end

  def down
    # there is no down for this, as the enum will not allow setting this back to nil
  end
end
