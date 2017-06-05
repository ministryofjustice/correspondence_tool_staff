module CTS
  class Cases < Thor
    include Thor::Rails unless SKIP_RAILS

    CASE_JOURNEYS = {
      unflagged: [
        :unassigned,
        :awaiting_responder,
        :drafting,
        :awaiting_dispatch,
        :responded,
        :closed,
      ],
      flagged_for_dacu_approval: [
        :unassigned,
        :flagged_for_dacu_clearance,
        :awaiting_responder,
        :approver_assignment_accepted,
        :drafting,
        :pending_dacu_clearance,
        :awaiting_dispatch,
        :responded,
        :closed,
      ]
    }

    default_command :list

    desc 'list', 'List cases in the system.'
    def list
      columns = [
        :id,
        :number,
        :subject,
        :current_state,
        :requires_clearance?
      ]
      tp Case.all, columns
    end

    desc "clear", "Delete all cases in the database"
    def clear
      CTS::check_environment
      puts "Deleting all cases"
      Case.all.map(&:destroy)
    end

    desc 'create all|<states> [-n n] [-d] [-x]', 'Create <-n> cases in the specified states'
    long_desc <<~LONGDESC
    The create command takes the following sub commands:
      \x5 - all:        Create a number of cases in all states
      \x5 - <states>:   Create a number of cases in the specified state(s)

      Multiple states can be specified.

      Valid states are as follows:
           \x5 unassigned
           \x5 flagged_for_dacu_clearance
           \x5 awaiting_responder
           \x5 approver_assignment_accepted
           \x5 drafting
           \x5 pending_dacu_clearance
           \x5 awaiting_dispatch
           \x5 responded
           \x5 closed

      The following switches can be specified
      \x5 -n<number>    Create <number> cases in each state (default 2)
      \x5 -d            Create cases which require DACU disclosure
      \x5 -x            Clear all existing cases before creating

      e.g.
      \x5./cts create unassigned drafting -n3 -d
      \x5./cts create all -x
    LONGDESC
    option :n, type: :numeric
    option :d, type: :boolean
    option :x, type: :boolean
    option :dry_run, type: :boolean
    # rubocop:disable Metrics/CyclomaticComplexity
    def create(*args)
      @end_states = []
      @number_to_create = options[:n] || 2
      @add_dacu_disclosure = options[:d] || false
      @clear_cases = options[:x] || false
      @dry_run = options.fetch(:dry_run, false)
      @invalid_params = false

      CTS::check_environment
      validate_teams_and_users_populated
      parse_params(args)

      clear if @clear_cases

      puts "Creating #{@number_to_create} cases in each of the following states: #{@end_states.join(', ')}"
      puts "Flagging each for DACU disclosure" if @add_dacu_disclosure
      cases = @end_states.map do |target_state|
        journey = find_case_journey_for_state target_state.to_sym
        kase = nil
        journey.each do |state|
          if @dry_run
            puts "transition to '#{state}"
          else
            kase = __send__("transition_to_#{state}", kase)
          end
        end
        kase
      end
      unless @dry_run
        tp cases, [:id, :number, :current_state, :requires_clearance?]
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    private

    def validate_teams_and_users_populated
      validate_teams_populated
      validate_users_populated
    end

    def validate_teams_populated
      @dacu_team, @disclosure_team, @hmcts_team, @hr_team, @laa_team = ['DACU', 'DACU Disclosure', 'Legal Aid Agency', 'HR', 'HMCTS North East Response Unit(RSU)'].map do |team_name|
        teams = Team.where(name: team_name)
        if teams.count > 1
          error "ERROR: multiple entries found for team: #{team_name}"
          exit 2
        elsif teams.count == 0
          error "ERROR: team missing: #{team_name}"
          error "Run 'rake db:seed:dev:users' to populate teams and users"
          exit 2
        else
          teams.first
        end
      end
    end

    def validate_users_populated
      begin
        @dacu_manager = @dacu_team.managers.first ||
                        raise("DACU BMT missing users")
        @disclosure_approver = @disclosure_team.approvers.first ||
                               raise("DACU Disclosure missing users")
        @hmcts_responder = @hmcts_team.responders.first ||
                           raise("HMCTS missing users")
      rescue => ex
        error "Error validating users:"
        error ex.message
        error "Run 'rake db:seed:dev:users' to populate teams and users"
        exit 3
      end
    end

    def transition_to_unassigned(_cases)
      cases = []
      @number_to_create.times do
        kase = FactoryGirl.create(:case,
                                  name: Faker::Name.name,
                                  subject: Faker::Company.catch_phrase,
                                  message: Faker::Lorem.paragraph(10, true, 10),
                                  managing_team: @dacu_team)
        cases << kase
      end
      cases
    end

    def transition_to_flagged_for_dacu_clearance(cases)
      cases.each do |kase|
        result = CaseFlagForClearanceService.new(user:@dacu_manager, kase:kase).call
        unless result == :ok
          raise "Could not flag case for clearance, case id: #{kase.id}, user id: #{@dacu_manager.id}, result: #{service.result}"
        end
      end
    end

    def transition_to_awaiting_responder(cases)
      cases.each do |kase|
        kase.responding_team = @hmcts_team
        kase.assign_responder(@dacu_manager, @hmcts_team)
      end
    end

    def transition_to_drafting(cases)
      cases.each do |kase|
        kase.responder_assignment.update_attribute(:user, @hmcts_responder)
        kase.responder_assignment_accepted(@hmcts_responder, @hmcts_team)
      end
    end

    def transition_to_approver_assignment_accepted(cases)
      cases.each do |kase|
        service = CaseAcceptApproverAssignmentService.new(
          assignment: kase.approver_assignment,
          user: @disclosure_approver,
        )
        unless service.call
          raise "Could not accept approver assignment, case id: #{kase.id}, user id: #{@disclosure_approver.id}, result: #{service.result}"
        end
      end
    end

    def transition_to_awaiting_dispatch(cases)
      cases.each do |kase|
        if kase.approver_assignment
          result = CaseApprovalService
                     .new(user: @disclosure_approver, kase: kase).call
          unless result == :ok
            raise "Could not approve case response , case id: #{kase.id}, user id: #{@disclosure_approver.id}, result: #{result}"
          end
        else
          ResponseUploaderService.new(kase, @hmcts_responder, nil, nil).seed!
          kase.state_machine.add_responses!(@hmcts_responder, @hmcts_team, kase.attachments)
        end
      end
    end

    def transition_to_responded(cases)
      cases.each do |kase|
        kase.respond(@hmcts_responder)
      end
    end

    def transition_to_pending_dacu_clearance(cases)
      cases.each do |kase|
        ResponseUploaderService.new(kase, @hmcts_responder, nil).seed!
        kase.add_response_to_flagged_case(@hmcts_responder, kase.attachments)
      end
    end

    def transition_to_closed(cases)
      cases.each do |kase|
        kase.prepare_for_close
        kase.update(date_responded: Date.today, outcome_name: 'Granted in full')
        kase.close(@dacu_manager)
      end
    end

    def find_case_journey_for_state(state)
      CASE_JOURNEYS.each do |name, states|
        unless @add_dacu_disclosure && name != :flagged_for_dacu_approval
          pos = states.find_index(state)
          return states.take(pos + 1) if pos
        end
      end
      return []
    end

    def parse_params(args)
      args.each { |arg| process_arg(arg) }

      if @invalid_params
        error 'Program terminating'
        exit 1
      elsif @end_states.empty?
        error 'No states provided, please see help for what states are available.'
        exit 1
      end
    end

    def process_arg(arg)
      if arg == 'all'
        @end_states += if @add_dacu_disclosure
                         CASE_JOURNEYS[:flagged_for_dacu_approval]
                       else
                         CASE_JOURNEYS[:unflagged]
                       end
      elsif find_case_journey_for_state(arg.to_sym).any?
        @end_states << arg
      else
        error "Unrecognised parameter: #{arg}"
        @invalid_params = true
      end
    end
  end
end
