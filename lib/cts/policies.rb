module CTS
  class Policies < Thor
    include Thor::Rails unless SKIP_RAILS

    desc "check USER CASE", "Check policies for a user/case combination"
    long_desc <<~EOD
      Check the policies for a given user and case. Runs all the policies
      and displays whether it succeeded or not, and if not which checks failed.
      This is meant as a handy debugging tool to understand why a user cannot do
      something with a particular case.

      Command-Line Args:
        USER:     ID or full name for a user
        CASE:     ID or case number for a case
        POLICIES: list of patterns to use to generate list of policies to check
                  (default is "can_.*")

      Examples:
        ./cts policies check 19 239
        ./cts policies check 'Preston Offman' 239
        ./cts policies check 'Preston Offman' 170621004
        ./cts policies check 19 239 can_view_case_details
        ./cts policies check 19 239 can_view_case_details can_approve_case
    EOD
    def check(*args)
      raise("No user provided.") if args.empty?
      raise("No case provided.") if args.length == 1

      user = CTS.find_user(args.shift)
      puts "Found User: id:#{user.id} name:#{user.full_name}"
      kase = CTS.find_case(args.shift)
      puts "Found Case: id:#{kase.id} number:#{kase.number}"
      check_policies = (args.presence || ['\?$'])
      puts "Checking policies: #{check_policies}"

      policy = Pundit.policy!(user, kase)
      all_policy_methods = policy.public_methods false
      policy_patterns = check_policies.map { |p| Regexp.new p }
      policies_pattern = Regexp.union(policy_patterns)
      policy_methods = all_policy_methods.grep(policies_pattern)
      policy_method_padding = policy_methods.max_by(&:length).length
      policy_methods.each do |policy_method|
        result = policy.__send__(policy_method)
        printf "%#{policy_method_padding}s: " % policy_method
        if result
          puts "YES"
        else
          puts "NO, failed checks: #{CasePolicy.failed_checks.join(', ')}"
        end
      end
    end
  end
end
