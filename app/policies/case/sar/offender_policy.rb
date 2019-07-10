class Case::SAR::OffenderPolicy < Case::SAR::StandardPolicy
  # @todo (mseedat-moj): Allow all users to view Offender SAR during MVP dev
  def show?
    clear_failed_checks
  end
end
