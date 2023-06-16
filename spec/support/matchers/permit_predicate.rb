# This replicates the 'permit' matcher that is provided by Pundit, but
# specialises it for Workflows::Predicates. I couldn't think of a better name
# than "permit" (allow is used, for example) so we define it as that name but
# in a module and ask that any tests that want to use it include it into their
# spec groups.

module PermitPredicate
  RSpec::Matchers.define :permit_only_these_combinations do |*permitted_combinations|
    match do |predicate|
      permitted_combinations.each do |user, kase|
        unless all_users.key? user
          @error_message = "User #{user} not found in all_users()."
          return false
        end
        unless all_cases.key? kase
          @error_message = "Case #{kase} not found in all_cases()."
          return false
        end
      end

      @errors = []
      all_users.each do |user_type, user|
        all_cases.each do |case_type, kase|
          predicates = Workflows::Predicates.new(user:, kase:)
          result = predicates.send(predicate)
          if [user_type, case_type].in?(permitted_combinations) ^ result
            debugger if @debug_on_error && $stdout.tty?
            @errors << [user_type, case_type, result]
          end
        end
      end
      @errors.empty?
    end

    # Use this to run debugger if a particular combination fails a test.
    # Handy to be able to get a peek into the context where the error occured.
    # The debugger is also protected so that it doesn't appear if STDOUT is not
    # a TTY.
    chain :debug do
      @debug_on_error = true
    end

    failure_message do |predicate|
      if @errors.present?
        @error_message = "Predicate #{predicate} failed for the combinations:\n"
        @errors.each do |user, kase, result|
          @error_message << if result
                              "  [#{user}, #{kase}] did not expect it, but got true\n"
                            else
                              "  [#{user}, #{kase}] expected true, but got false\n"
                            end
        end
      end
      @error_message
    end
  end
end
