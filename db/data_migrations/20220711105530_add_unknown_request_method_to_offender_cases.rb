class AddUnknownRequestMethodToOffenderCases < ActiveRecord::DataMigration
  def up
    Case::Base.offender_sar.find_each { |k| k.update_attribute(:request_method, "unknown") unless k.readonly? } # rubocop:disable Rails/SkipsModelValidations
  end
end
