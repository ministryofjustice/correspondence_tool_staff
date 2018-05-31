require 'cts'

# rubocop:disable Metrics/ClassLength
module CTS::Cases
  class CreateSAR
    attr_accessor :logger, :options, :flag

    def initialize(logger, options = {})
      @logger = logger
      @options = options
      @klass = @options[:type].nil? ? Case::Base : @options[:type].constantize
      @options.delete(:type)
    end

    def call(target_states, kase = nil)
      CTS::check_environment unless options[:force]
      parse_options(options)

      target_states.map do |target_state|
        journey = find_case_journey_for_state target_state.to_sym
        logger.info "creating case in #{target_state}"
        kase ||= new_case
        if options[:dry_run]
          kase.validate!
        else
          kase.save!
        end
        run_transitions(kase, target_state, journey)
        kase
      end .flatten
    end

    def new_case
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
      @klass.new(
        subject_full_name:  name,
        email:              options.fetch(:email, Faker::Internet.email(name)),
        subject:            options.fetch(:subject, Faker::Company.catch_phrase),
        third_party:        false,
        message:            options.fetch(:message,
                                          Faker::Lorem.paragraph(10, true, 10)),
        subject_type:       options.fetch(:subject_type,
                                          Case::SAR.subject_types.keys.sample),
        received_date:      received_date,
        created_at:         created_at,
        dirty:              options.fetch(:dirty, true)
      )
    end

    private

    def parse_options(options) # rubocop:disable Metrics/CyclomaticComplexity
      @target_states = []
      @flag = nil
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

    def transition_to_closed(kase)
      kase.prepare_for_close
      kase.update(date_responded: Date.today,
                  info_held_status: CaseClosure::InfoHeldStatus.held,
                  outcome_name: 'Granted in full')
      kase.close(CTS::dacu_manager)
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def journeys_to_check
      CTS::Cases::Constants::CASE_JOURNEYS.find_all do |name, _states|
        @flag.blank?
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
      CASE_JOURNEYS[:unflagged]
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
                               BusinessUnit.responding.sample
                             end
                           else
                             CTS::find_team(options[:responding_team])
                           end
      if @responding_team.responders.none?
        create_responder(@responding_team)
      end
      @responding_team
    end

    def create_responder(responding_team)
      name = Faker::Name.name
      user = User.create!(full_name: name,
                          email: Faker::Internet.email(name),
                          password: 'correspondence')
      TeamsUsersRole.create(user: user, team: responding_team, role: 'responder')
    end
  end
end
# rubocop:enable Metrics/ClassLength
