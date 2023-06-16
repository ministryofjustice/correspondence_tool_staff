task csm: :environment do
  mgr = ConfigurableStateMachine::Manager.instance
  mgr.state_machine_for("moj", "foi", "standard")
end
