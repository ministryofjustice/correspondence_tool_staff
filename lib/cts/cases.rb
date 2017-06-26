module CTS
  # rubocop:disable Metrics/ClassLength
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
        :awaiting_responder,
        :approver_assignment_accepted,
        :drafting,
        :pending_dacu_disclosure_clearance,
        :awaiting_dispatch,
        :responded,
        :closed,
      ],
      flagged_for_press_office: [
        :unassigned,
        :awaiting_responder,
        :approver_assignment_accepted,
        :drafting,
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

    desc 'create OPTIONS all|<states>', 'Create cases in the specified states'
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

    Examples:
      ./cts cases create --created-at='2017-06-20 09:36:00' drafting
      ./cts cases create -x -n2 all
      ./cts cases create --dry-run -p awaiting_responder
    LONGDESC

    option :number, aliases: 'n', type: :numeric,
           desc: 'Number of cases to create (per state). [1]'
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
    option :created_at, type: :string
    # option :dacu_manager, type: :string
    # option :dacu_approver, type: :string

    def create(*args)
      parse_options

      CTS::check_environment

      @invalid_params = false
      parse_params(args)

      puts "Creating #{@number_to_create} cases in each of the following states:"
      puts "\t" + @end_states.join("\n\t")
      puts "Flagging each for DACU Disclosure clearance" if @add_dacu_disclosure
      puts "Flagging each for Press Office clearance" if @add_press_office
      puts "\n"

      clear if @clear_cases

      cases = @end_states.map do |target_state|
        journey = find_case_journey_for_state target_state.to_sym
        cases = nil
        journey.each do |state|
          if @dry_run
            puts "transition to '#{state}'"
          else
            cases = __send__("transition_to_#{state}", cases)
            cases.each(&:reload)
          end
        end
        cases
      end
      unless @dry_run
        tp cases, [:id, :number, :current_state, :requires_clearance?]
      end
    end

    desc 'show', 'Show case details.'
    def show(*args)
      args.each do |case_identifier|
        kase = CTS::find_case(case_identifier)
        ap kase

        puts "\nAssignments:"
        tp kase.assignments, [:id, :state, :role, :team_id, :user_id]

        puts "\nTransitions:"
        tp kase.transitions, :id, :event, :to_state, :user_id,
           metadata: { width: 40 }

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
      @responding_team ||= if !options.has_key?(:responding_team)
                             if options.has_key?(:responder)
                               responder.responding_teams.first
                             else
                               CTS::hmcts_team
                             end
                           else
                             CTS::find_team(options[:responding_team])
                           end
    end

    def parse_options
      @end_states = []
      @number_to_create = options.fetch(:number, 1)
      @add_dacu_disclosure = options.fetch(:dacu_disclosure, false)
      @add_press_office = options.fetch(:press_office, false)
      @clear_cases = options.fetch(:clear, false)
      @dry_run = options.fetch(:dry_run, false)
      @created_at = options[:created_at]

      if @add_dacu_disclosure && @add_press_office
        raise "cannot handle flagging for dacu disclosure and press office yet"
      end
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
        error "Journeys checked:"
        journeys_to_check.each do |name, states|
          error "  #{name}: #{states.join(', ')}"
        end
        @invalid_params = true
      end
    end

    def flag_for_dacu_disclosure(*cases)
      cases.each do |kase|
        result = CaseFlagForClearanceService.new(
          user: CTS::dacu_manager,
          kase: kase,
          team: Team.dacu_disclosure
        ).call
        unless result == :ok
          raise "Could not flag case for clearance by DACU Disclosure, case id: #{kase.id}, user id: #{CTS::dacu_manager.id}, result: #{result}"
        end
      end
    end

    def flag_for_press_office(*cases)
      cases.each do |kase|
        result = CaseFlagForClearanceService.new(
          user: CTS::dacu_manager,
          kase: kase,
          team: Team.press_office
        ).call
        unless result == :ok
          raise "Could not flag case for clearance by press office, case id: #{kase.id}, user id: #{CTS::dacu_manager.id}, result: #{result}"
        end
      end
    end

    def transition_to_unassigned(_cases)
      cases = []
      @number_to_create.times do
        kase = FactoryGirl.create(:case,
                                  name: Faker::Name.name,
                                  subject: Faker::Company.catch_phrase,
                                  message: Faker::Lorem.paragraph(10, true, 10),
                                  managing_team: CTS::dacu_team,
                                  created_at: @created_at)
        flag_for_dacu_disclosure(kase) if @add_dacu_disclosure
        flag_for_press_office(kase) if @add_press_office
        cases << kase
      end
      cases
    end

    def transition_to_awaiting_responder(cases)
      cases.each do |kase|
        kase.responding_team = responding_team
        kase.assign_responder(CTS::dacu_manager, responding_team)
      end
    end

    def transition_to_drafting(cases)
      cases.each do |kase|
        kase.responder_assignment.accept(responder)
      end
    end

    def transition_to_approver_assignment_accepted(cases)
      cases.each do |kase|
        if @add_dacu_disclosure
          assignment = kase.approver_assignments
                         .where(team: CTS::dacu_disclosure_team).first
          user = CTS::dacu_disclosure_approver
        elsif @add_press_office
          assignment = kase.approver_assignments
                         .where(team: CTS::press_office_team).first
          user = CTS::press_office_approver
        end

        service = CaseAcceptApproverAssignmentService.new(
          assignment: assignment,
          user: user
        )

        unless service.call
          raise "Could not accept approver assignment, case id: #{kase.id}, user id: #{dacu_disclosure.id}, result: #{service.result}"
        end
      end
    end

    def transition_to_awaiting_dispatch(cases)
      cases.each do |kase|
        if kase.approver_assignments.for_user(CTS::dacu_disclosure_approver).any?
          result = CaseApprovalService
                     .new(user: CTS::dacu_disclosure_approver, kase: kase).call
          unless result == :ok
            raise "Could not approve case response , case id: #{kase.id}, user id: #{CTS::dacu_disclosure_approver.id}, result: #{result}"
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

    def transition_to_pending_dacu_disclosure_clearance(cases)
      cases.each do |kase|
        ResponseUploaderService.new(kase, responder, nil).seed!
        kase.add_response_to_flagged_case(responder, kase.attachments)
      end
    end

    def transition_to_closed(cases)
      cases.each do |kase|
        kase.prepare_for_close
        kase.update(date_responded: Date.today, outcome_name: 'Granted in full')
        kase.close(CTS::dacu_manager)
      end
    end

    def journeys_to_check
      CASE_JOURNEYS.find_all do |name, _states|
        !(@add_dacu_disclosure || @add_press_office) ||
          (@add_dacu_disclosure && name == :flagged_for_dacu_approval) ||
          (@add_press_office && name == :flagged_for_press_office)
      end
    end

    def find_case_journey_for_state(state)
      journeys_to_check.each do |_name, states|
        pos = states.find_index(state)
        return states.take(pos + 1) if pos
      end
      return []
    end
  end
  # rubocop:enable Metrics/ClassLength
end
