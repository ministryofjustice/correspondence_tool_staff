module CTS
  class Cases
    # rubocop:disable Metrics/ClassLength
    class Create
      attr_accessor :command, :args, :options

      CASE_JOURNEYS = {
        unflagged: [
          :awaiting_responder,
          :drafting,
          :awaiting_dispatch,
          :responded,
          :closed,
        ],
        flagged_for_dacu_disclosure: [
          :awaiting_responder,
          :accepted_by_dacu_disclosure,
          :drafting,
          :pending_dacu_disclosure_clearance,
          :awaiting_dispatch,
          :responded,
          :closed,
        ],
        flagged_for_press_office: [
          :awaiting_responder,
          :taken_on_by_press_office,
          :accepted_by_dacu_disclosure,
          :drafting,
        ]
      }

      def initialize(command, options, args)
        @command = command
        @options = options
        @args = args

        parse_options(options)
        CTS::check_environment

        @invalid_params = false
        parse_params(args)
      end

      def call
        puts "Creating #{@number_to_create} cases in each of the following states:"
        puts "\t" + @end_states.join("\n\t")
        puts "Flagging each for DACU Disclosure clearance" if @flag.present?
        puts "Flagging each for Press Office clearance" if @flag == 'press'
        puts "\n"

        clear if @clear_cases

        cases = []
        begin
          @end_states.map do |target_state|
            journey = find_case_journey_for_state target_state.to_sym
            @number_to_create.times do |n|
              puts "creating case #{target_state} ##{n}"
              kase = create_case()
              run_transitions(kase, target_state, journey, n)
              cases << kase
            end
          end
        ensure
          unless @dry_run
            tp cases, [:id, :number, :current_state, :requires_clearance?]
          end
        end
      end

      private

      def parse_options(options)
        @end_states = []
        @number_to_create = options.fetch(:number, 1)
        @flag = options.fetch(:flag_for_team,
                              options.fetch(:flag_for_disclosure, nil))
        @clear_cases = options.fetch(:clear, false)
        @dry_run = options.fetch(:dry_run, false)
        @created_at = options[:created_at]
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
          @end_states += get_journey_for_flagged_state(@flag)
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

      def create_case()
        kase = FactoryGirl.create(:case,
                                  name: Faker::Name.name,
                                  subject: Faker::Company.catch_phrase,
                                  message: Faker::Lorem.paragraph(10, true, 10),
                                  managing_team: CTS::dacu_team,
                                  created_at: @created_at)
        flag_for_dacu_disclosure(kase) if @flag.present?
        kase
      end

      def run_transitions(kase, target_state, journey, n)
        journey.each do |state|
          begin
            if @dry_run
              puts "  transition to '#{state}'"
            else
              __send__("transition_to_#{state}", kase)
              kase.reload
            end
          rescue => exx
            command.error "Error occured on case #{target_state} id:#{n}: #{exx.message}"
            command.error ""
            command.error "Case unsuccessfully transitioned to #{state}:"
            command.error "---------------------------------------"
            command.error kase.ai
            raise
          end
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

      def transition_to_awaiting_responder(kase)
        kase.responding_team = responding_team
        kase.assign_responder(CTS::dacu_manager, responding_team)
      end

      def transition_to_drafting(kase)
        kase.responder_assignment.accept(responder)
      end

      def transition_to_accepted_by_dacu_disclosure(kase)
        assignment = kase.approver_assignments
                       .where(team: CTS::dacu_disclosure_team).first
        user = CTS::dacu_disclosure_approver
        service = CaseAcceptApproverAssignmentService.new(
          assignment: assignment,
          user: user
        )

        unless service.call
          raise "Could not accept approver assignment, case id: #{kase.id}, user id: #{user.id}, result: #{service.result}"
        end
      end

      def transition_to_taken_on_by_press_office(kase)
        result = CaseFlagForClearanceService.new(
          user: press_officer,
          kase: kase,
          team: Team.press_office
        ).call
        unless result == :ok
          raise "Could not flag case for clearance by press office, case id: #{kase.id}, user id: #{CTS::dacu_manager.id}, result: #{result}"
        end
      end

      def transition_to_awaiting_dispatch(kase)
        if kase.approver_assignments.for_user(CTS::dacu_disclosure_approver).any?
          result = CaseApprovalService
                     .new(user: CTS::dacu_disclosure_approver, kase: kase).call
          unless result == :ok
            raise "Could not approve case response , case id: #{kase.id}, user id: #{CTS::dacu_disclosure_approver.id}, result: #{result}"
          end
        else
          ResponseUploaderService.new(kase, responder, nil, nil).seed!
          kase.state_machine.add_responses!(responder,
                                            responding_team,
                                            kase.attachments)
        end
      end

      def transition_to_responded(kase)
        kase.respond(responder)
      end

      def transition_to_pending_dacu_disclosure_clearance(kase)
        ResponseUploaderService.new(kase, responder, nil).seed!
        kase.add_response_to_flagged_case(responder, kase.attachments)
      end

      def transition_to_closed(kase)
        kase.prepare_for_close
        kase.update(date_responded: Date.today, outcome_name: 'Granted in full')
        kase.close(CTS::dacu_manager)
      end

      def journeys_to_check
        CASE_JOURNEYS.find_all do |name, _states|
          @flag.blank? ||
            name == :flagged_for_dacu_disclosure ||
            (@flag == 'press' && name == :flagged_for_press_office)
        end
      end

      def find_case_journey_for_state(state)
        journeys_to_check.each do |_name, states|
          pos = states.find_index(state)
          return states.take(pos + 1) if pos
        end
        return []
      end

      def get_journey_for_flagged_state(flag)
        case @flag
        when 'disclosure'
          CASE_JOURNEYS[:flagged_for_dacu_displosure]
        when 'press'
          CASE_JOURNEYS[:flagged_for_press_office]
        else
          CASE_JOURNEYS[:unflagged]
        end
      end

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

      def press_officer
        Team.press_office.approvers.first
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
