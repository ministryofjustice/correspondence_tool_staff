# Utility method to help us setup policy.
#
# Without this approach, we will have multiple versions of this method each time
# we need to stub out the policies

def allow_case_policies(kase, *policy_names)
  @policy ||= double 'Pundit::Policy'
  policy_names.each do |policy_name|
    allow(@policy).to receive(policy_name).and_return(true)
  end
  allow(view).to receive(:policy).with(kase).and_return(@policy)
end

def disallow_case_policies(kase, *policy_names)
  @policy ||= double 'Pundit::Policy'
  policy_names.each do |policy_name|
    allow(@policy).to receive(policy_name).and_return(false)
  end
  allow(view).to receive(:policy).with(kase).and_return(@policy)
end
