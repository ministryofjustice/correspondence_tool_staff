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
     - all:        Create a number of cases in all states
     - <states>:   Create a number of cases in the specified state(s)

     Multiple states can be specified.

     Valid states are as follows:
        unassigned
        flagged_for_dacu_clearance
        awaiting_responder
        approver_assignment_accepted
        drafting
        pending_dacu_clearance
        awaiting_dispatch
        responded
        closed
    LONGDESC

    option :number, aliases: 'n', type: :numeric,
           desc: 'Number of cases to create (per state). [2]'
    option :dacu_disclosure, aliases: 'd', type: :boolean,
           desc: 'Flag cases for clearance by DACU Disclosure.'
    option :press_office, aliases: 'p', type: :boolean,
           desc: 'Flag cases for clearance by Press Office.'
    option :clear, aliases: :x, type: :boolean,
           desc: 'Clear existing cases before creating.'
    option :dry_run, type: :boolean,
           desc: 'Print out what states cases will be created in.'
    option :responder, aliases: :r, type: :string,
           desc: 'ID or name of responder to use for case assignments.'
    option :responding_team, aliases: :t, type: :string,
           desc: 'ID or name of responding team to use for case assignments.'
    # option :dacu_manager, type: :string
    # option :dacu_approver, type: :string

    # rubocop:disable Metrics/CyclomaticComplexity
    def create(*args)
      @end_states = []
      @number_to_create = options[:n] || 2
      @add_dacu_disclosure = options[:d] || false
      @add_press_office = options[:press_office] || false
      @clear_cases = options[:x] || false
      @dry_run = options.fetch(:dry_run, false)

      CTS::check_environment

      @invalid_params = false
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

    desc 'show', 'Show case details.'
    def show(*args)
      args.each do |case_identifier|
        kase = if case_identifier.match(/^\d+$/)
                 Case.where(['id = ? or number = ?',
                             case_identifier,
                             case_identifier]).first
               end
        ap kase

        puts "\nAssignments:"
        tp kase.assignments, [:id, :state, :role, :team_id, :user_id]

        puts "\nTransitions:"
        tp kase.transitions, [:id, :event, :to_state, :user_id, :metadata]

        puts "\nAttachments:"
        tp kase.attachments, [:id, :type, :key, :preview_key]
      end
    end

    private

    def responder
      @responder ||= if !options.has_key?(:responder)
                       if responding_team.responders.empty?
                         raise "Responding team '#{responding_team.name}' has no responders."
                       else
                         responding_team.responders.first
                       end
                     else
                       CTS::find_user(options[:responder])
                     end
    end

    def responding_team
      if !options.has_key?(:responding_team) && options.has_key?(:responder)
        @responding_team ||= responder.responding_teams.first
      else
        @responding_team ||= CTS::find_team(
          options.fetch(:responding_team, 'HMCTS North East Response Unit(RSU)')
        )
      end
    end

    def dacu_manager
      @dacu_manager ||= if dacu_team.managers.blank?
                          raise 'DACU team has no managers assigned.'
                        else
                          dacu_team.managers.first
                        end
    end

    def dacu_approver
      @dacu_approver ||= if dacu_disclosure_team.approvers.blank?
                           raise 'DACU Disclosure team has no approvers assigned.'
                         else
                           dacu_disclosure_team.approvers.first
                         end
    end

    def dacu_team
      @dacu_team ||= CTS::find_team('DACU')
    end

    def dacu_disclosure_team
      @dacu_disclosure_team ||= CTS::find_team('DACU Disclosure')
    end

    def press_office_team
      @dacu_team ||= CTS::find_team('Press Office')
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

    def transition_to_unassigned(_cases)
      cases = []
      @number_to_create.times do
        kase = FactoryGirl.create(:case,
                                  name: Faker::Name.name,
                                  subject: Faker::Company.catch_phrase,
                                  message: Faker::Lorem.paragraph(10, true, 10),
                                  managing_team: CTS::dacu_team)
        cases << kase
      end
      cases
    end

    def transition_to_flagged_for_dacu_clearance(cases)
      cases.each do |kase|
        result = CaseFlagForClearanceService.new(user:dacu_manager, kase:kase).call
        unless result == :ok
          raise "Could not flag case for clearance, case id: #{kase.id}, user id: #{dacu_manager.id}, result: #{service.result}"
        end
      end
    end

    def transition_to_awaiting_responder(cases)
      cases.each do |kase|
        kase.responding_team = responding_team
        kase.assign_responder(dacu_manager, responding_team)
        kase.reload
      end
    end

    def transition_to_drafting(cases)
      cases.each do |kase|
        kase.responder_assignment.accept(responder)
      end
    end

    def transition_to_approver_assignment_accepted(cases)
      cases.each do |kase|
        service = CaseAcceptApproverAssignmentService.new(
          assignment: kase.approver_assignment,
          user: dacu_approver,
        )
        unless service.call
          raise "Could not accept approver assignment, case id: #{kase.id}, user id: #{dacu_disclosure.id}, result: #{service.result}"
        end
      end
    end

    def transition_to_awaiting_dispatch(cases)
      cases.each do |kase|
        if kase.approver_assignment
          result = CaseApprovalService
                     .new(user: dacu_disclosure, kase: kase).call
          unless result == :ok
            raise "Could not approve case response , case id: #{kase.id}, user id: #{dacu_disclosure.id}, result: #{result}"
          end
        else
          ResponseUploaderService.new(kase, responder, nil, nil).seed!
          kase.state_machine.add_responses!(responder, responding_team, kase.attachments)
        end
      end
    end

    def transition_to_responded(cases)
      cases.each do |kase|
        kase.respond(responder)
      end
    end

    def transition_to_pending_dacu_clearance(cases)
      cases.each do |kase|
        ResponseUploaderService.new(kase, responder, nil).seed!
        kase.add_response_to_flagged_case(responder, kase.attachments)
      end
    end

    def transition_to_closed(cases)
      cases.each do |kase|
        kase.prepare_for_close
        kase.update(date_responded: Date.today, outcome_name: 'Granted in full')
        kase.close(dacu_manager)
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
  end
end
