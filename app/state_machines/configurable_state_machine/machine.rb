module ConfigurableStateMachine
  class Machine
    def initialize(config:, kase:)
      @config = config
      @kase = kase
      @events = nil
    end

    # Ideally there shouldn't be any other definitions of states other than state machine yaml file. but
    # tried to remove it with a method in manager and ended up with an error below
    # >> Circular dependency detected while autoloading constant in one of policy ruby code
    # Couldn't think of easy way to fix it, so just added missing states here
    def self.states
      %w[unassigned
         awaiting_responder
         drafting
         pending_dacu_clearance
         pending_press_office_clearance
         pending_private_office_clearance
         awaiting_dispatch
         responded
         data_to_be_requested
         waiting_for_data
         ready_for_vetting
         vetting_in_progress
         ready_to_copy
         ready_to_dispatch
         to_be_assessed
         data_review_required
         response_required
         waiting
         invalid_submission
         stopped
         closed]
    end

    def self.states_for_closed_cases
      %w[closed]
    end

    def events
      @events ||= gather_all_events
    end

    def initial_state
      @config.initial_state
    end

    def current_state
      @kase.current_state || initial_state
    end

    def permitted_events(current_user_or_id)
      user = current_user_or_id.instance_of?(User) ? current_user_or_id : User.find(current_user_or_id)
      events = permitted_events_for_role_and_user(user:, state: @kase.current_state)
      events.flatten.uniq.sort
    end

    # determines whether or not an event can be triggered
    # params:
    # * event_name: The event to be triggered
    # * metadata:   A hash, which must contain the key :acting_user or :acting_user_id.  May also contain
    #               :acting_team or :acting_team_id which will be used to determine roles if roles not set
    # * roles:      Either a string denoting the role, or an array of roles, or nil.  If nil, the role will be determined
    #               from either the acting_team or acting_user
    #

    def can_trigger_event?(event_name:, metadata:, roles: nil)
      configs = configs_for_event(event_name:, metadata:, roles:)
      configs.map { |config| event_triggerable_in_config?(config:, user: @user) }.any?
    end

    def configs_for_event(event_name:, metadata:, roles:)
      set_users_and_roles(metadata:, roles:)
      configs = []
      @roles.each do |role|
        role_config = @config.user_roles[role]
        next if role_config.nil?

        role_state_config = role_config.states[@kase.current_state]
        event_config = fetch_event_config(config: role_state_config, event: event_name)
        configs << event_config
      end
      configs
    end

    def event_triggerable_in_config?(config:, user:)
      if config.nil?
        false
      elsif config.if.nil?
        true
      elsif predicate_is_true?(predicate: config.if, user:)
        true
      else
        false
      end
    end

    def config_for_event(event_name:, metadata:, roles: nil)
      set_users_and_roles(metadata:, roles:)
      @roles.each do |role|
        role_config = @config.user_roles[role]
        next if role_config.nil?

        role_state_config = role_config.states[@kase.current_state]
        event_config = fetch_event_config(config: role_state_config, event: event_name)
        if event_config
          return check_event_config(config: event_config, user: @user)
        end
      end
      nil
    end

    def set_users_and_roles(metadata:, roles:)
      @roles = roles
      @roles = [roles] if roles.is_a?(String)
      @roles = extract_roles_from_metadata(metadata) if roles.nil?
      @user = extract_user_from_metadata(metadata)
    end

    # intercept trigger event  methods, which all end in a !
    #
    def method_missing(method, *args)
      if method.to_s =~ /(.+)!$/
        event_name = ::Regexp.last_match(1)
        trigger_event(event: event_name.to_sym, params: args.first)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      method.to_s =~ /(.+)!$/ || super
    end

    def event_name(event)
      if events.include?(event.to_sym)
        specific_key = "event.case/#{@kase.type_abbreviation.downcase}.#{event}"
        default_key = "event.#{event}"
        I18n.t(specific_key, default: I18n.t(default_key))
      end
    end

    def call_guards_for_target_state(target_state, metadata)
      guards = target_state[:guards]
      guards.blank? ||
        guards.all? { |g| g.call(object, last_transition, metadata) }
    end

    def next_state_for_event(event, params)
      user = extract_user_from_metadata(params)
      if can_trigger_event?(event_name: event, metadata: params)
        event = event.to_sym
        role = first_role_that_can_trigger_event_on_case(event_name: event, metadata: params, user:).first
        user_role_config = @config.user_roles[role]
        if user_role_config.nil?
          raise InvalidEventError.new(kase: @kase,
                                      user: params[:acting_user],
                                      event:,
                                      role:,
                                      message: "No such role")
        end
        state_config = user_role_config.states[@kase.current_state]
        if state_config.nil? || state_config.to_hash.keys.exclude?(event)
          raise InvalidEventError.new(role:,
                                      kase: @kase,
                                      user: params[:acting_user],
                                      event:,
                                      message: "No state, or event in this state found")
        end
        event_config = state_config[event]
        if event_config.to_h.key?(:transition_to)
          event_config.transition_to
        elsif event_config.to_h.key?(:transition_to_using)
          result_from_class_and_method(class_and_method: event_config.transition_to_using, user:)
        else
          @kase.current_state
        end
      else
        raise InvalidEventError.new(role: nil,
                                    kase: @kase,
                                    user:,
                                    event:,
                                    message: "Not permitted to trigger event")
      end
    end

    def teams_that_can_trigger_event_on_case(event_name:, user:)
      available_teams = []
      possible_teams_for_case(user).each do |team|
        if is_team_available_for_this_event?(event_name, user, team)
          available_teams << team
        end
      end
      available_teams
    end

  private

    def possible_teams_for_case(user)
      if (@kase.teams & user.teams.active).any?
        @kase.permitted_teams & user.teams.active
      else
        user.teams.active
      end
    end

    def is_team_available_for_this_event?(event_name, user, team)
      team.active? && can_trigger_event_for_the_case?(event_name:, acting_team: team, user:)
    end

    def first_role_that_can_trigger_event_on_case(event_name:, metadata:, user:)
      roles = user.roles_for_case(@kase)
      roles.delete_if { |role| !can_trigger_event?(event_name:, metadata:, roles: [role]) }
    end

    def event_present_and_triggerable?(role_state_config:, event:, user:)
      return false if role_state_config.nil?

      config = role_state_config[event]
      return false if config.nil?

      if config.to_h.key?(:if)
        predicate_is_true?(predicate: config.if, user:) ? true : false
      else
        true
      end
    end

    def key_present_but_nil?(config, key)
      config.to_h.key?(key) && config[key].nil?
    end

    def fetch_event_config(config: role_state_config, event: event_name)
      if config.nil? || !config.to_h.key?(event)
        nil
      elsif config[event].nil?
        RecursiveOpenStruct.new
      else
        config[event]
      end
    end

    def check_event_config(config:, user:)
      if config.nil?
        RecursiveOpenStruct.new
      elsif config.if.nil? || predicate_is_true?(predicate: config.if, user:)
        config
      end
    end

    def can_trigger_event_for_the_case?(event_name:, acting_team:, user:)
      event = event_name.to_sym
      role =  acting_team.role
      user_role_config = @config.user_roles[role]
      if user_role_config.nil?
        return false
      end

      state_config = user_role_config.states[@kase.current_state]
      if state_config.nil? || state_config.to_hash.keys.exclude?(event)
        return false
      end
      unless can_trigger_event?(
        event_name: event,
        metadata: { acting_user: user, acting_team: },
        roles: [role],
      )
        return false
      end

      true
    end

    # in a transaction, write the case transition record, and transition the case
    # params are guaranteed to have the following keys:
    # * :acting_user (this corresponds to the current_user)
    # * :acting_team
    #
    def trigger_event(event:, params:)
      event = event.to_sym
      raise ::ConfigurableStateMachine::ArgumentError.new(kase: @kase, event:, params:) if !params.key?(:acting_user) || !params.key?(:acting_team)

      role = params[:acting_team].role
      user_role_config = @config.user_roles[role]
      if user_role_config.nil?
        raise InvalidEventError.new(
          kase: @kase,
          user: params[:acting_user],
          event:,
          role:,
          message: "No state machine config for role #{role}",
        )
      end
      user = extract_user_from_metadata(params)
      state_config = user_role_config.states[@kase.current_state]
      if state_config.nil? || state_config.to_hash.keys.exclude?(event)
        raise InvalidEventError.new(
          role:,
          kase: @kase,
          user: params[:acting_user],
          event:,
          message: "No event #{event} for role #{role} and case state " \
                   "#{@kase.current_state}",
        )
      end
      event_config = state_config[event]
      if can_trigger_event?(event_name: event, metadata: params)
        ActiveRecord::Base.transaction do
          to_state = find_destination_state(event_config:, user:)
          to_workflow = find_destination_workflow(event_config:, user:)
          CaseTransition.unset_most_recent(@kase)
          write_transition(event:, to_state:, to_workflow:, params:)
          @kase.update!(current_state: to_state, workflow: to_workflow)
          execute_after_transition_method(event_config:, user:, metadata: params)
        end
      else
        raise InvalidEventError.new(
          role:,
          kase: @kase,
          user: params[:acting_user],
          event:,
          message: "Event #{event} not permitted for role #{role} and " \
                   "case state #{@kase.current_state}",
        )
      end
    end

    def extract_roles_from_metadata(metadata)
      team = extract_team_from_metadata(metadata)
      user = extract_user_from_metadata(metadata)
      if team.nil?
        user.roles
      elsif user.roles_for_team(team).any?
        user.roles_for_team(team).map(&:role)
      else
        [team.role]
      end
    end

    def extract_team_from_metadata(metadata)
      if metadata.key?(:acting_team)
        metadata[:acting_team]
      elsif metadata.key?(:acting_team_id)
        Team.find(metadata[:acting_team_id])
      end
    end

    def extract_user_from_metadata(metadata)
      if metadata.key?(:acting_user_id)
        User.find(metadata[:acting_user_id])
      else
        metadata[:acting_user]
      end
    end

    def permitted_events_for_role_and_user(user:, state:)
      events = []
      user.roles.each do |role|
        role_config = @config.user_roles[role]
        next if role_config.nil?

        role_state_config = role_config.states[state]
        role_state_config.to_h.each_key do |event|
          event_config = role_state_config[event]
          events << event if event_triggerable_for_user?(event_config:, user:)
        end
      end
      events
    end

    def event_triggerable_for_user?(event_config:, user:)
      if event_config.to_h.key?(:if)
        predicate_is_true?(predicate: event_config[:if], user:)
      else
        true
      end
    end

    def predicate_is_true?(predicate:, user:)
      klass, method = predicate.split("#")
      predicate_object = klass.constantize.new(user:, kase: @kase)
      predicate_object.__send__(method) ? true : false
    end

    def find_destination_state(event_config:, user:)
      if event_config.to_h.key?(:transition_to)
        event_config.transition_to
      elsif event_config.to_h.key?(:transition_to_using)
        result_from_class_and_method(class_and_method: event_config.transition_to_using, user:)
      else
        @kase.current_state
      end
    end

    def result_from_class_and_method(class_and_method:, user:)
      klass, method = class_and_method.split("#")
      conditional_object = klass.constantize.new(user:, kase: @kase)
      conditional_object.__send__(method)
    end

    def find_destination_workflow(event_config:, user:)
      config = event_config.to_h
      if config.key?(:switch_workflow_using)
        result_from_class_and_method(class_and_method: event_config.switch_workflow_using, user:)
      elsif config.key?(:switch_workflow)
        event_config.switch_workflow
      else
        @kase.workflow
      end
    end

    def execute_after_transition_method(event_config:, user:, metadata:)
      if event_config.to_h.key?(:after_transition)
        class_and_method = event_config.after_transition
        klass, method = class_and_method.split("#")
        after_object = klass.constantize.new(user:, kase: @kase, metadata:)
        after_object.__send__(method)
      end
    end

    def write_transition(event:, to_state:, to_workflow:, params:)
      attrs = {
        event:,
        to_state:,
        to_workflow:,
        sort_key: CaseTransition.next_sort_key(@kase),
        most_recent: true,
        acting_user_id: params[:acting_user]&.id,
        acting_team_id: params[:acting_team]&.id,
        target_user_id: params[:target_user]&.id,
        target_team_id: params[:target_team]&.id,
      }
      @kase.transitions.create!(attrs.merge(clear_params_for_transition(params)))
    end

    def gather_all_events
      events = []
      if @config.to_hash[:permitted_events].present?
        events = @config.to_hash[:permitted_events].map(&:to_sym)
      else
        @config.to_hash[:user_roles].each_value do |role_config|
          role_config[:states].each_value do |role_state_config|
            events << role_state_config.keys
          end
        end
        events.flatten.uniq.sort
      end
    end

    def clear_params_for_transition(params)
      cloned_params = params.clone
      %i[acting_user acting_team target_user target_team num_attachments disable_hook].each do |key|
        cloned_params.delete(key)
      end
      cloned_params
    end
  end
  # rubocop:enable Metrics/ClassLength
end
