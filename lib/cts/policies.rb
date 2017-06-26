module CTS
  class Policies < Thor
    include Thor::Rails unless SKIP_RAILS

    desc 'check USER CASE', 'Check policies for a user/case combination'
    long_desc <<~EOD
      Check the policies for a given user and case. Runs all the policies
      and displays whether it succeeded or not, and if not which checks failed.
      This is meant as a handy debugging tool to understand why a user can't do
      something with a particular case.

      Command-Line Args:
        USER: ID or full name for a user
        CASE: ID or case number for a case

      Examples:
        ./cts policies check 19 239
        ./cts policies check 'Preston Offman' 239
        ./cts policies check 'Preston Offman' 170621004
        ./cts policies check -p can_view_case_details\? 19 239
        ./cts policies check -p can_view_case_details\?,can_approve_case\? 19 239
    EOD
    option :policy, aliases: 'p', type: :string,
           desc: 'Only check given policy/policies.'
    def check(*args)
      check_policies = options.fetch(:policy, '').split(/, */).map(&:to_sym)

      raise("No user provided.") if args.length == 0
      raise("No case provided.") if args.length == 1
      user = CTS::find_user(args.shift)
      puts "Found User: id:#{user.id} name:#{user.full_name}"
      kase = CTS::find_case(args.shift)
      puts "Found Case: id:#{kase.id} number:#{kase.number}"

      policy = Pundit.policy!(user, kase)
      policy_methods = policy.public_methods.grep(/^can_.*\?$/)
      unless check_policies.empty?
        puts "Checking policies: #{options[:policy]}"
        policy_methods.reject! { |m| !m.in? check_policies }
      end
      policy_method_padding = policy_methods.max_by(&:length).length
      policy_methods.each do |policy_method|
        result = policy.__send__(policy_method)
        printf "%#{policy_method_padding}s: " % policy_method
        if result
          puts 'YES'
        else
          puts "NO, failed checks: #{CasePolicy.failed_checks.join(', ')}"
        end
      end
    end
  end
end
