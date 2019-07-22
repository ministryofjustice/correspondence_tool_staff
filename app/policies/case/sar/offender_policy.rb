class Case::SAR::OffenderPolicy < Case::SAR::StandardPolicy
  def create?
    clear_failed_checks
    check_user_is_a_manager
  end
end
