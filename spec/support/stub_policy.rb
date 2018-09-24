# Utility method to help us setup policy.
#
# Without this approach, we will have multiple versions of this method each time
# we need to stub out the policies

def allow_case_policies(case_or_class, *policy_names)
  policy_class = Pundit::PolicyFinder.new(case_or_class).policy!
  policy_names.each do |policy_name|
    allow_any_instance_of(policy_class).to receive(policy_name)
                                             .and_return(true)
  end
end

def disallow_case_policies(case_or_class, *policy_names)
  policy_class = Pundit::PolicyFinder.new(case_or_class).policy!
  policy_names.each do |policy_name|
    allow_any_instance_of(policy_class).to receive(policy_name)
                                             .and_return(false)
  end
end
