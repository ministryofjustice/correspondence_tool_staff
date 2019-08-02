module GovUKDateFixes
  extend ActiveSupport::Concern

  # This method is here to fix an issue with the gov_uk_date_fields
  # where the validation fails since the internal list of instance
  # variables lacks the date_of_birth field from the json properties
  #     NoMethodError: undefined method `valid?' for nil:NilClass
  #     ./app/state_machines/configurable_state_machine/machine.rb:256
  def set_date_of_birth
    @case.date_of_birth = @case.date_of_birth
  end

end
