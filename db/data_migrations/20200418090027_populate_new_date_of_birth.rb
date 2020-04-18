class PopulateNewDateOfBirth < ActiveRecord::DataMigration
  def up
    Case::Base.where("type = ?", "Case::SAR::Offender").each {|kase| kase.update_attribute(:date_of_birth_new, kase.date_of_birth) }
  end
end
