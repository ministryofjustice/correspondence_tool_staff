module PermitTriggerEvent
  RSpec::Matchers.define :permit_event_to_be_triggered_only_by do |*permitted_combinations|
    match do |event|
      permitted_combinations.each do |user, team, kase|
        unless all_users.key?(user)
          @error_message = "User #{user} not found in all_users()."
          return false
        end

        unless all_teams.key?(team)
          @error_message = "Team #{team} not found in all_teams()."
        end

        unless all_cases.key?(kase)
          @error_message = "Case #{kase} not found in all_cases()."
          return false
        end
      end


      @errors = []
      all_users.each do |user_type, user|
        all_teams.each do |team_type, team|
          all_cases.each do |case_type, kase|
            state_machine = kase.state_machine
            result = state_machine.can_trigger_event?(event_name: event, metadata: {acting_user: user, acting_team: team})
            if [user_type, team_type, case_type].in?(permitted_combinations) ^ result
              (binding).pry if @debug_on_error && $stdout.tty?
              @errors << [user_type, team_type, case_type, result]
            end
          end
        end
      end
      @errors.empty?
    end

    # Use this to run binding.pry if a particular combination fails a test.
    # Handy to be able to get a peek into the context where the error occured.
    # The debugger is also protected so that it doesn't appear if STDOUT is not
    # a TTY.
    chain :debug do
      @debug_on_error = true
    end

    failure_message do |event|
      unless @errors.nil? || @errors.empty?
        @error_message = "Event #{event} failed for the combinations:\n"
        @errors.each do |user_type, team_type, kase_type, result|
          if result
            @error_message <<
                "  [#{user_type}, #{team_type},  #{kase_type}] did not expect it, but got true\n"
          else
            @error_message <<
                "  [#{user_type}, #{team_type},  #{kase_type}] expected true, but got false\n"
          end
        end
      end
      @error_message
    end
  end
end
