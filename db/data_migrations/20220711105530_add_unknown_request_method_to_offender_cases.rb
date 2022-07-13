class AddUnknownRequestMethodToOffenderCases < ActiveRecord::DataMigration
  def up
    Case::Base.offender_sar.each { |k| k.update_attribute(:request_method, "unknown") }
  end
end