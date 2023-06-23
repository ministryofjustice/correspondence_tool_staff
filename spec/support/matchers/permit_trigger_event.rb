module PermitTriggerEvent
  RSpec::Matchers.define :permit_event_to_be_triggered_only_by do |*permitted_combinations|
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
                                                    acting_team: team,
                                                  })

          # config.present? would return false for {}, which we don't want.
          if !config.nil? && @transition_to.present?
            next_state = state_machine.next_state_for_event(event,
                                                            acting_user: user,
                                                            acting_team: team)
            # result = !config.nil? && @transition_to == next_state
            result = @transition_to == next_state
          else
            result = !config.nil?
          end

          next unless [user_type, case_type].in?(permitted_combinations) ^ result

          debugger if @debug_on_error && $stdout.tty? # rubocop:disable Lint/Debugger
          # this is handy to be able to step through what failed
          #
          #    kase : the case currently being tested
          #    user : the user currently being tested
          @errors << [user_type, case_type, !config.nil?]
        end
      end
      @errors.empty?
    end

    chain :with_transition_to do |target_state|
      @transition_to = target_state.to_s
    end

    # Use this to run debugger if a particular combination fails a test.
    # Handy to be able to get a peek into the context where the error occured.
    # The debugger is also protected so that it doesn't appear if STDOUT is not
    # a TTY.
    chain :debug do
      @debug_on_error = true
    end

    failure_message do |event|
      if @errors.present?
        @error_message = "Event #{event} failed for the combinations:\n"
        @errors.each do |user_type, kase_type, result|
          @error_message << if result
                              "  We did not expect the event to be triggerable for #{user_type} on #{kase_type} cases, but it is.\n"
                            else
                              "  We expected the event to be triggerable for #{user_type} on #{kase_type} cases, but it is not.\n"
                            end
        end
      end
      @error_message
    end
  end
end
