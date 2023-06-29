class Case::OverturnedICO::FOIPolicy < Case::FOI::StandardPolicy
  def new?
    @user.manager?
  end

  # this method only needs to exist here until such time as we have
  # trigger overturned sars enabled, at which time we can delete it here
  # and it will use the base policy
  #
  def request_further_clearance?
    clear_failed_checks

    check_user_is_a_manager_for_case && check_can_trigger_event(:request_further_clearance)
  end
end
