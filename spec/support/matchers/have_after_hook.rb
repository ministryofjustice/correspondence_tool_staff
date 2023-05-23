module PermitTriggerEvent
  RSpec::Matchers.define :have_after_hook do |*permitted_combinations|
    match do |event|
      permitted_combinations.each do |user_and_team, kase|
        unless all_user_teams.key?(user_and_team)
          @error_message = "User #{user_and_team} not found in all_user_teams()."
          return false
        end

        unless all_cases.key?(kase)
          @error_message = "Case #{kase} not found in all_cases()."
          return false
        end
      end

      @errors = []
      all_user_teams.each do |user_type, user_and_team|
        all_cases.each do |case_type, kase|
          user, team = user_and_team
          state_machine = kase.state_machine
          config = state_machine.config_for_event(event_name: event,
                                                  metadata: {
                                                    acting_user: user,
                                                    acting_team: team
                                                  })

            result = !config.nil? && config.after_transition == @expected_hook
          if [user_type, case_type].in?(permitted_combinations) ^ result
            debugger if @debug_on_error && $stdout.tty?
            @errors << [user_type, case_type, !config.nil?]
          end
        end
      end
      @errors.empty?
    end

    chain :with_hook do |klass, method|
      @expected_hook = "#{klass}##{method}"
    end

    # Use this to run debugger if a particular combination fails a test.
    # Handy to be able to get a peek into the context where the error occured.
    # The debugger is also protected so that it doesn't appear if STDOUT is not
    # a TTY.
    chain :debug do
      @debug_on_error = true
    end

    failure_message do |event|
      unless @errors.nil? || @errors.empty?
        @error_message = "Event #{event} failed for the combinations:\n"
        @errors.each do |user_type, kase_type, result|
          if result
            @error_message <<
                "  The after hook #{@expected_hook} was not present for #{user_type} on #{kase_type}.\n"
          else
            @error_message <<
                "  We expected the after hook #{@expected_hook} to be present for #{user_type} on #{kase_type} cases, but it is not.\n"
          end
        end
      end
      @error_message
    end
  end
end
