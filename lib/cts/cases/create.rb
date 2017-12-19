require 'cts'

# rubocop:disable Metrics/ClassLength
module CTS::Cases
  class Create
    attr_accessor :logger, :options, :flag

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
        :pending_dacu_disclosure_clearance,
        :pending_press_office_clearance,
      ],
      flagged_for_private_office: [
        :awaiting_responder,
        :taken_on_by_private_office,
        :accepted_by_dacu_disclosure,
        :drafting,
        :pending_dacu_disclosure_clearance,
        :pending_press_office_clearance,
        :pending_private_office_clearance,
      ]
    }

    def initialize(logger, options = {})
      @logger = logger
      @options = options
    end

    def call(target_states, kase = nil)
      CTS::check_environment unless options[:force]
      parse_options(options)

      target_states.map do |target_state|
        journey = find_case_journey_for_state target_state.to_sym
        @number_to_create.times.map do |n|
          logger.info "creating case #{target_state} ##{n}"
          kase ||= new_case
          kase.save!
          flag_for_dacu_disclosure(kase) if @flag.present?
          run_transitions(kase, target_state, journey, n)
          kase
        end
      end .flatten
    end

    def new_case
      foi = Category.find_by(abbreviation: 'FOI')
      name = options.fetch(:name, Faker::Name.name)
      created_at = if options[:created_at].present?
                     0.business_days.after(DateTime.parse(options[:created_at]))
                   else
                     0.business_days.after(4.business_days.ago)
                   end
      received_date = if options.key? :received_date
                        options[:received_date]
                      else
                        0.business_days.after(4.business_days.ago)
                      end
      Case::Base.new(
        name:            name,
        email:           options.fetch(:email, Faker::Internet.email(name)),
        category:        foi,
        delivery_method: options.fetch(:delivery_method, 'sent_by_email'),
        subject:         options.fetch(:subject, Faker::Company.catch_phrase),
        message:         options.fetch(:message,
                                       Faker::Lorem.paragraph(10, true, 10)),
        requester_type:  options.fetch(:requester_type,
                                       Case::Base.requester_types.keys.sample),
        received_date:   received_date,
        created_at:      created_at,
      )
    end

    private

    # rubocop:disable Metrics/CyclomaticComplexity
    def parse_options(options)
      @target_states = []
      @number_to_create = options.fetch(:number, 1)
      @flag = if options.key?(:flag_for_disclosure)
                options[:flag_for_disclosure] ? 'disclosure' : nil
              elsif options.key?(:flag_for_team)
                options[:flag_for_team]
              else
                nil
              end
      @clear_cases = options.fetch(:clear, false)
      @dry_run = options.fetch(:dry_run, false)
      @created_at = options[:created_at]
      if options[:received_date]
        @recieved_date = options[:received_date]
      elsif @created_at.present? &&
            DateTime.parse(@created_at) < DateTime.now
        @received_date = @created_at
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def process_target_state_param(state)
      if state == 'all'
        @target_states += get_journey_for_flagged_state(@flag)
      elsif find_case_journey_for_state(state.to_sym).any?
        @target_states << state
      else
        logger.error "Unrecognised parameter: #{state}"
        logger.error "Journeys checked:"
        journeys_to_check.each do |name, states|
          logger.error "  #{name}: #{states.join(', ')}"
        end
        @invalid_params = true
      end
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
          logger.error "Error occured on case #{target_state} id:#{n}: #{exx.message}"
          logger.error ""
          logger.error "Case unsuccessfully transitioned to #{state}:"
          logger.error "---------------------------------------"
          logger.error kase.ai
          raise
        end
      end
    end

    def flag_for_dacu_disclosure(*cases)
      cases.each do |kase|
        dts = DefaultTeamService.new(kase)
        result = CaseFlagForClearanceService.new(
          user: CTS::dacu_manager,
          kase: kase,
          team: dts.approving_team,
        ).call
        unless result == :ok
          raise "Could not flag case for clearance by DACU Disclosure, case id: #{kase.id}, user id: #{CTS::dacu_manager.id}, result: #{result}"
        end
      end
    end

    def transition_to_awaiting_responder(kase)
      kase.responding_team = responding_team

      cars = CaseAssignResponderService.new team: responding_team,
                                            kase: kase,
                                            role: 'responding',
                                            user: CTS::dacu_manager
      cars.call
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
      call_case_flag_for_clearance_service(kase, CTS::press_officer, CTS::press_office_team)
    end

    def transition_to_taken_on_by_private_office(kase)
      call_case_flag_for_clearance_service(kase, CTS::private_officer, CTS::private_office_team)
    end

    def transition_to_awaiting_dispatch(kase)
      if kase.approver_assignments.for_user(CTS::dacu_disclosure_approver).any?
        call_case_approval_service(CTS::dacu_disclosure_approver, kase)
      else
        ResponseUploaderService
          .new(kase, responder, BypassParamsManager.new({}), nil)
          .seed!('spec/fixtures/eon.pdf')
        kase.state_machine.add_responses!(acting_user: responder,
                                          filenames: kase.attachments)
      end
    end

    def transition_to_responded(kase)
      kase.respond(responder)
    end

    def transition_to_pending_dacu_disclosure_clearance(kase)
      rus = ResponseUploaderService.new(kase,
                                        responder,
                                        BypassParamsManager.new({}),
                                        nil)
      rus.seed!('spec/fixtures/eon.pdf')
      kase.state_machine.add_response_to_flagged_case!(responder,
                                                       responding_team,
                                                       kase.attachments)
    end

    def transition_to_pending_press_office_clearance(kase)
      if kase.approver_assignments.for_user(CTS::dacu_disclosure_approver).any?
        call_case_approval_service(CTS::dacu_disclosure_approver, kase)
      end
    end

    def transition_to_pending_private_office_clearance(kase)
      if kase.approver_assignments.for_user(CTS::press_officer).any?
        call_case_approval_service(CTS::press_officer, kase)
      end
    end

    def transition_to_closed(kase)
      kase.prepare_for_close
      kase.update(date_responded: Date.today,
                  info_held_status: CaseClosure::InfoHeldStatus.held,
                  outcome_name: 'Granted in full')
      kase.close(CTS::dacu_manager)
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def journeys_to_check
      CASE_JOURNEYS.find_all do |name, _states|
        @flag.blank? ||
          (@flag == 'disclosure' && name == :flagged_for_dacu_disclosure) ||
          (@flag == 'press' && name == :flagged_for_press_office) ||
          (@flag == 'private' && name == :flagged_for_private_office)
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def find_case_journey_for_state(state)
      journeys_to_check.each do |_name, states|
        pos = states.find_index(state)
        return states.take(pos + 1) if pos
      end
      return []
    end

    def get_journey_for_flagged_state(flag)
      case flag
      when 'disclosure'
        CASE_JOURNEYS[:flagged_for_dacu_displosure]
      when 'press'
        CASE_JOURNEYS[:flagged_for_press_office]
      when 'private'
        CASE_JOURNEYS[:flagged_for_private_office]
      else
        CASE_JOURNEYS[:unflagged]
      end
    end

    def responder
      @responder ||= if !options.key?(:responder)
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
      @responding_team ||= if !options.key?(:responding_team)
                             if options.key?(:responder)
                               responder.responding_teams.first
                             else
                               CTS::hmcts_team
                             end
                           else
                             CTS::find_team(options[:responding_team])
                           end
    end

    def press_officer
      BusinessUnit.press_office.approvers.first
    end

    def call_case_approval_service(user, kase)
      result = CaseApprovalService
                 .new(user: user, kase: kase).call
      unless result == :ok
        raise "Could not approve case response , case id: #{kase.id}, user id: #{user.id}, result: #{result}"
      end
    end

    def call_case_flag_for_clearance_service(kase, user, team)
      service = CaseFlagForClearanceService.new user: user, kase: kase, team: team
      result = service.call
      unless result == :ok
        raise "Could not flag case for clearance, case id: #{kase.id}, user id: #{user.id}, result: #{result}"
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
