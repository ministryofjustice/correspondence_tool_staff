module ConfigurableStateMachine
  #rubocop:disable Metrics/ClassLength
  class Machine

    def initialize(config:, kase:)
      @config = config
      @kase = kase
      @events = nil
    end

    def events
      @events ||= gather_all_events
    end

    def configurable?
      true
    end

    def initial_state
      @config.initial_state
    end

    def current_state
      @kase.current_state || initial_state
    end

    def permitted_events(current_user_or_id)
      user = current_user_or_id.instance_of?(User) ? current_user_or_id : User.find(current_user_or_id)
      events = permitted_events_for_role_and_user(user: user, state: @kase.current_state)
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
      result = false
      roles = [roles] if roles.is_a?(String)
      roles = extract_roles_from_metadata(metadata) if roles.nil?
      user = extract_user_from_metadata(metadata)
      roles.each do |role|
        role_config = @config.user_roles[role]
        next if role_config.nil?
        role_state_config =  role_config.states[@kase.current_state]
        if key_present_but_nil?(role_state_config, event_name.to_sym)
          result = true
        else
          result = event_present_and_triggerable?(role_state_config: role_state_config, event: event_name, user: user)
        end
        break if result == true
      end
      result
    end

    # intercept trigger event  methods, whcih all end in a !
    #
    def method_missing(method, *args)
      if method.to_s =~ /(.+)!$/
        event_name = $1
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
        I18n.t("event.#{event}", default: event.to_s.humanize)
      end
    end

    # def get_next_target_state_for_event(event_name, metadata)
    #   target_states = get_event_target_states!(event_name)
    #   target_states.find do |target_state|
    #     call_guards_for_target_state(target_state, metadata)
    #   end
    # end

    def call_guards_for_target_state(target_state, metadata)
      guards = target_state[:guards]
      guards.blank? ||
        guards.all? { |g| g.call(object,last_transition,metadata) }
    end

    #rubocop:disable Metrics/CyclomaticComplexity
    #rubocop:disable Metrics/MethodLength
    def next_state_for_event(event, params)
      user = extract_user_from_metadata(params)
      if can_trigger_event?(event_name: event, metadata: params)
        event = event.to_sym
        role = first_role_that_can_trigger_event_on_case(event_name: event, metadata: params, user: user).first
        user_role_config = @config.user_roles[role]
        raise InvalidEventError.new(kase: @kase,
                                    user: params[:acting_user],
                                    event: event,
                                    role: role,
                                    message: "No such role") if user_role_config.nil?  ###
        state_config = user_role_config.states[@kase.current_state]
        if state_config.nil? || !state_config.to_hash.keys.include?(event)
          raise InvalidEventError.new(role: role,
                                      kase: @kase,
                                      user: params[:acting_user],
                                      event: event,
                                      message: "No state, or event in this state found")
        end
        event_config = state_config[event]
        if event_config.to_h.key?(:transition_to)
          event_config.transition_to
        elsif event_config.to_h.key?(:transition_to_using)
          result_from_class_and_method(class_and_method: event_config.transition_to_using, user: user)
        else
          @kase.current_state
        end
      else
        raise InvalidEventError.new(role: nil,
                                    kase: @kase,
                                    user: user,
                                    event: event,
                                    message: "Not permitted to trigger event")
      end
    end
    #rubocop:enable Metrics/CyclomaticComplexity
    #rubocop:enable Metrics/MethodLength

    private

    def first_role_that_can_trigger_event_on_case(event_name:, metadata:, user:)
      roles = user.roles_for_case(@kase)
      roles.delete_if { | role| !can_trigger_event?(event_name: event_name, metadata: metadata, roles: [role]) }
    end

    def event_present_and_triggerable?(role_state_config:, event:, user:)
      return false if role_state_config.nil?
      config = role_state_config[event]
      return false if config.nil?
      if config.to_h.key?(:if)
        return predicate_is_true?(predicate: config.if, user: user) ? true : false
      else
        return true
      end
    end

    def key_present_but_nil?(config, key)
      config.to_h.key?(key) && config[key].nil?
    end



    # in a transaction, write the case transition record, and transition the case
    # params are guaranteed to have the following keys:
    # * :acting_user (this corresponds to the current_user)
    # * :acting_team
    #
    #rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    def trigger_event(event:, params:)
      event = event.to_sym
      raise ::ConfigurableStateMachine::ArgumentError.new(kase: @kase, event: event, params: params) if !params.key?(:acting_user) || !params.key?(:acting_team)
      role =  params[:acting_team].role
      user_role_config = @config.user_roles[role]
      if user_role_config.nil?
        raise InvalidEventError.new(
                kase: @kase,
                user: params[:acting_user],
                event: event,
                role: role,
                message: "No state machine config for role #{role}"
              )
      end
      user = extract_user_from_metadata(params)
      raise InvalidEventError.new(kase: @kase, user: params[:acting_user], event: event, role: role) if user_role_config.nil?
      state_config = user_role_config.states[@kase.current_state]
      if state_config.nil? || !state_config.to_hash.keys.include?(event)
        raise InvalidEventError.new(
                role: role,
                kase: @kase,
                user: params[:acting_user],
                event: event,
                message: "No event #{event} for role #{role} and case state " +
                         "#{@kase.current_state}"
              )
      end
      event_config = state_config[event]
      if can_trigger_event?(event_name: event, metadata: params)
        ActiveRecord::Base.transaction do
          to_state = find_destination_state(event_config: event_config, user: user)
          to_workflow = find_destination_workflow(event_config: event_config, user: user)
          CaseTransition.unset_most_recent(@kase)
          write_transition(event: event, to_state: to_state, to_workflow: to_workflow, params: params)
          @kase.update!(current_state: to_state, workflow: to_workflow)
          execute_after_transition_method(event_config: event_config, user: user)
        end
      else
        raise InvalidEventError.new(
                role: role,
                kase: @kase,
                user: params[:acting_user],
                event: event,
                message: "Event #{event} not permitted for role #{role} and " +
                         "case state #{@kase.current_state}"
              )
      end
    end
    #rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength


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
      else
        nil
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
        role_state_config.to_h.keys.each do |event|
          event_config = role_state_config[event]
          events << event if event_triggerable_for_user?(event_config: event_config, user: user)
        end
      end
      events
    end

    def event_triggerable_for_user?(event_config:, user:)
      if event_config.to_h.key?(:if)
        predicate_is_true?(predicate: event_config[:if], user: user)
      else
        true
      end
    end

    def predicate_is_true?(predicate:, user:)
      klass, method = predicate.split('#')
      predicate_oject = klass.constantize.new(user: user, kase: @kase)
      predicate_oject.__send__(method)
    end

    def find_destination_state(event_config:, user:)
      if event_config.to_h.key?(:transition_to)
        event_config.transition_to
      elsif event_config.to_h.key?(:transition_to_using)
        result_from_class_and_method(class_and_method: event_config.transition_to_using, user: user)
      else
        @kase.current_state
      end
    end

    def result_from_class_and_method(class_and_method:, user:)
      klass, method = class_and_method.split('#')
      conditional_object = klass.constantize.new(user: user, kase: @kase)
      conditional_object.__send__(method)
    end

    def find_destination_workflow(event_config:, user:)
      config = event_config.to_h
      if config.key?(:switch_workflow_using)
        result_from_class_and_method(class_and_method: event_config.switch_workflow_using, user: user)
      elsif config.key?(:switch_workflow)
        event_config.switch_workflow
      else
        @kase.workflow
      end
    end

    def execute_after_transition_method(event_config:, user:)
      if event_config.to_h.key?(:after_transition)
        class_and_method = event_config.after_transition
        klass, method = class_and_method.split('#')
        after_object = klass.constantize.new(user: user, kase: @kase)
        after_object.__send__(method)
      end
    end

    def write_transition(event:, to_state:, to_workflow:, params:)
      attrs = {
        event: event,
        to_state: to_state,
        to_workflow: to_workflow,
        sort_key: CaseTransition.next_sort_key(@kase),
        most_recent: true,
        acting_user_id: params[:acting_user]&.id,
        acting_team_id: params[:acting_team]&.id,
        target_user_id: params[:target_user]&.id,
        target_team_id: params[:target_team]&.id,
      }
      cloned_params = params.clone
      %i{ acting_user acting_team target_user target_team num_attachments }.each do |key|
        cloned_params.delete(key)
      end
      @kase.transitions.create!(attrs.merge(cloned_params))
    end

    def gather_all_events
      events = []
      if @config.to_hash[:permitted_events].present?
        events = @config.to_hash[:permitted_events].map(&:to_sym)
      else
        @config.to_hash[:user_roles].each do |_role, role_config|
          role_config[:states].each do |_state, role_state_config|
            events << role_state_config.keys
          end
        end
        events.flatten.uniq.sort
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
