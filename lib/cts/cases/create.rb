require 'cts'

# rubocop:disable Metrics/ClassLength
module CTS::Cases
  class Create
    attr_accessor :logger, :options, :flag

    def initialize(logger, options = {})
      @logger = logger
      @options = options
      @klass = @options[:type].nil? ? Case::Base : @options[:type].constantize
      @options.delete(:type)
    end

    def call(target_state, kase = nil)
      CTS::check_environment unless options[:force]
      parse_options(options)

      journey = find_case_journey_for_state target_state.to_sym
      logger.info "creating case in #{target_state}"
      kase ||= new_case

      if options[:dry_run]
        kase.validate!
      else
        prepare_case(kase)
        kase.save!
      end

      return [:invalid, kase] if kase.invalid?

      flag_for_dacu_disclosure(kase) if @flag.present?
      run_transitions(kase, target_state, journey)
      [:ok, kase]
    end

    def new_case
      case @klass.to_s
      when 'Case::SAR' then new_sar_case
      when /^Case::ICO/ then new_ico_case
      when /^Case::FOI/ then new_foi_case
      when /^Case::OverturnedICO/ then new_overturned_case
      end
    end

    def new_ico_case
      @klass.new(
        message:              options.fetch(:message,
                                            Faker::Lorem.paragraph(10, true, 10)),
        received_date:        get_ico_received_date,
        external_deadline:    get_ico_external_deadline,
        internal_deadline:    get_ico_internal_deadline,
        created_at:           get_created_at_date,
        dirty:                options.fetch(:dirty, true),
        ico_officer_name:     options.fetch(:ico_officer_name, Faker::Name.name),
        ico_reference_number: options.fetch(:ico_reference_number, SecureRandom.hex),
      )
    end

    def new_foi_case
      name = options.fetch(:name, Faker::Name.name)

      @klass.new(
        name:            name,
        email:           options.fetch(:email, Faker::Internet.email(name)),
        delivery_method: options.fetch(:delivery_method, 'sent_by_email'),
        subject:         options.fetch(:subject, Faker::Company.catch_phrase),
        message:         options.fetch(:message,
                                       Faker::Lorem.paragraph(10, true, 10)),
        requester_type:  options.fetch(:requester_type,
                                       Case::FOI::Standard.requester_types.keys.sample),
        received_date:   get_foi_received_date,
        created_at:      get_created_at_date,
        dirty:           options.fetch(:dirty, true)
      )
    end

    def new_sar_case
      subject_full_name = options.fetch(:subject_full_name, Faker::Name.name)
        @klass.new(
          subject_full_name: options.fetch(:subject_full_name, Faker::Name.name),
          email:             options.fetch(:email, Faker::Internet.email(subject_full_name)),
          subject:           options.fetch(:subject, Faker::Company.catch_phrase),
          third_party:       options.fetch(:third_party, false),
          message:           options.fetch(:message,
                                           Faker::Lorem.paragraph(10, true, 10)),
          subject_type:      options.fetch(:subject_type,
                                           Case::SAR.subject_types.keys.sample),
          received_date:     get_sar_received_date,
          created_at:        get_created_at_date,
          reply_method:      options.fetch(:reply_method, 'send_by_email'),
          dirty:             options.fetch(:dirty, true)
        )
    end

    def new_overturned_case
      @klass.new(
        created_at:        get_created_at_date,
        dirty:             options.fetch(:dirty, true),
        email:             options.fetch(:email, Faker::Internet.email),
        external_deadline: get_overturned_external_deadline,
        internal_deadline: get_overturned_internal_deadline,
        received_date:     get_overturned_received_date,
        reply_method:      options.fetch(:reply_method, 'send_by_email'),
      )
    end

    private

    def get_foi_received_date
      options.fetch(:received_date) do
        0.business_days.after(4.business_days.ago)
      end
    end

    def get_ico_received_date
      options.fetch(:received_date) do
        0.business_days.ago
      end
    end

    def get_overturned_received_date
      options.fetch(:received_date) do
        0.business_days.ago
      end
    end

    def get_sar_received_date
      options.fetch(:received_date) do
        0.business_days.ago
      end
    end

    def get_ico_external_deadline
      options.fetch(:external_deadline) do
        20.business_days.after(get_ico_received_date)
      end
    end

    def get_ico_internal_deadline
      options.fetch(:internal_deadline) do
        10.business_days.before(get_ico_external_deadline)
      end
    end

    def get_overturned_external_deadline
      options.fetch(:external_deadline) do
        20.business_days.after(get_overturned_received_date)
      end
    end

    def get_overturned_internal_deadline
      options.fetch(:internal_deadline) do
        10.business_days.before(get_overturned_external_deadline)
      end
    end

    def get_created_at_date
      if options[:created_at].present?
        0.business_days.after(DateTime.parse(options[:created_at]))
      else
        0.business_days.after(4.business_days.ago)
      end
    end

    def parse_options(options) # rubocop:disable Metrics/CyclomaticComplexity
      @target_states = []
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
        @received_date = options[:received_date]
      elsif @created_at.present? &&
            DateTime.parse(@created_at) < DateTime.now
        @received_date = @created_at
      end
    end

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

    def run_transitions(kase, target_state, journey)
      journey.each do |state|
        begin
          if @dry_run
            logger.info "  transition to '#{state}'"
          else
            __send__("transition_to_#{state}", kase)
            kase.reload
          end
        rescue => exx
          logger.error "Error occured on case #{target_state}: #{exx.message}"
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
        ResponseUploaderService.seed!(
          kase: kase,
          current_user: responder,
          filepath: 'spec/fixtures/eon.pdf',
        )
        kase.state_machine.add_responses!(acting_user: responder,
                                          acting_team: kase.responding_team,
                                          filenames: kase.attachments)
      end
    end

    def transition_to_responded(kase)

      responder = kase.ico? ? kase.assigned_disclosure_specialist : kase.responder

      kase.update(date_responded: 5.business_days.after(kase.received_date))

      kase.respond(responder)
    end

    def transition_to_pending_dacu_disclosure_clearance(kase)
      case get_correspondence_type_abbreviation
      when :sar
        dts = DefaultTeamService.new(kase)

        kase.state_machine.progress_for_clearance!(acting_user: responder,
                                                   acting_team: kase.responding_team,
                                                   target_team: dts.approving_team)
      else
        ResponseUploaderService.seed!(
          kase: kase,
          current_user: responder,
          filepath: 'spec/fixtures/eon.pdf',
        )
        kase.state_machine.add_responses!(acting_user: responder,
                                          acting_team:responding_team,
                                          filenames: kase.attachments)
      end
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
      case kase.type_abbreviation
      when 'FOI', 'OVERTURNED_FOI' then transition_to_closed_for_foi(kase)
      when 'ICO' then transition_to_closed_for_ico(kase)
      when 'SAR', 'OVERTURNED_SAR' then transition_to_closed_for_sar(kase)
      else
        # No good having this fail silently.
        raise "Don't know how to close #{kase.type_abbreviation} cases."
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def journeys_to_check
      CTS::Cases::Constants::CASE_JOURNEYS[get_correspondence_type_abbreviation].find_all do |name, _states|
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
        CASE_JOURNEYS[get_correspondence_type_abbreviation][:flagged_for_dacu_displosure]
      when 'press'
        CASE_JOURNEYS[get_correspondence_type_abbreviation][:flagged_for_press_office]
      when 'private'
        CASE_JOURNEYS[get_correspondence_type_abbreviation][:flagged_for_private_office]
      else
        CASE_JOURNEYS[get_correspondence_type_abbreviation][:unflagged]
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
                               BusinessUnit.includes(:responders).responding.sample
                             end
                           else
                             CTS::find_team(options[:responding_team])
                           end
      if @responding_team.responders.none?
        create_responder(@responding_team)
      end
      @responding_team
    end

    def press_officer
      BusinessUnit.press_office.approvers.first
    end

    def call_case_approval_service(user, kase)
      result = CaseApprovalService
                 .new(user: user, kase: kase, bypass_params: nil).call
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

    def create_responder(responding_team)
      name = Faker::Name.name
      user = User.create!(full_name: name,
                          email: Faker::Internet.email(name),
                          password: 'correspondence')
      TeamsUsersRole.create(user: user, team: responding_team, role: 'responder')
    end

    def get_correspondence_type_abbreviation
      @klass.state_machine_name.to_sym.downcase
    end



    def transition_to_closed_for_foi(kase)
      kase.prepare_for_close
      kase.update(date_responded: Date.today,
                  info_held_status: CaseClosure::InfoHeldStatus.held,
                  outcome_abbreviation: 'granted')
      kase.close(CTS::dacu_manager)
    end

    def transition_to_closed_for_ico(kase)
      kase.prepare_for_close
      ico_decision = options.fetch(:ico_decision, Case::ICO::Base.ico_decisions.keys.sample )
      kase.update_attributes(date_ico_decision_received: Date.today, ico_decision: ico_decision)
      if kase.overturned?
        uploader = S3Uploader.new(kase, CTS::dacu_manager)
        uploader.add_file_to_case('spec/fixtures/ico_decision.png', :ico_decision)
        kase.ico_decision_comment = options.fetch(:ico_decision_comment, Faker::TvShows::DrWho.quote)
      end
      kase.save!
      kase.close(CTS::dacu_manager)
    end

    def transition_to_closed_for_sar(kase)
      kase.prepare_for_close
      kase.update(date_responded: Date.today, missing_info: false)
      kase.respond_and_close(responder)
    end

    def original_case_type(kase)
      case kase.type
      when 'Case::ICO::FOI' then 'Case::FOI::Standard'
      when 'Case::ICO::SAR' then 'Case::SAR'
      end
    end

    def original_appeal_case_type(kase)
      case kase.type
      when 'Case::OverturnedICO::FOI' then 'Case::ICO::FOI'
      when 'Case::OverturnedICO::SAR' then 'Case::ICO::SAR'
      end
    end

    def prepare_case(kase)
      case kase.class.to_s
      when /^Case::ICO:/ then prepare_ico_case(kase)
      when /^Case::OverturnedICO:/ then prepare_overturned_case(kase)
      end
    end

    def prepare_ico_case(kase)
      case_creator = CTS::Cases::Create.new(Rails.logger,
                                            type: original_case_type(kase) )
      (result, original_case) = case_creator.call(:closed)
      if result == :ok
        kase.original_case = original_case
      end
    end

    def prepare_overturned_case(kase)
      # TODO: The appeal case being created here should be flagged for
      #       disclosure, but that should be done by virtue of it being an ICO
      #       appeal, we shouldn't have to say so.
      case_creator = CTS::Cases::Create.new(Rails.logger,
                                            flag_for_disclosure: true,
                                            ico_decision: :overturned,
                                            type: original_appeal_case_type(kase))
      (result, original_ico_appeal) = case_creator.call(:closed)
      if result == :ok
        kase.original_case = original_ico_appeal.original_case
        kase.original_ico_appeal = original_ico_appeal
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
