module ConfigurableStateMachine

  class ConfigValidator

    attr_reader :errors

    def initialize(config, filename)
      @filename = filename
      @config = config
      @correspondence_types = []
      @correspondence_type = nil
      @workflow = nil
      @role = nil
      @permitted_workflows = []
      @permitted_user_roles = []
      @permitted_states = []
      @errors = []
    end

    def run
      validate_configs
      if errors.any?
        raise ConfigurationError.new(@errors)
      end
    end

    def validate_configs
      validate_exact_keys(@config, 'root', :preamble, :correspondence_types)
      validate_is_hash(@config, 'root', :preamble, :correspondence_types)
      if @config.preamble.present?
        if @config.preamble.is_a?(RecursiveOpenStruct)
          validate_exact_keys(@config.preamble,
                            'preamble',
                            :organisation,
                            :organisation_abbreviation,
                            :permitted_correspondence_types)
          validate_min_keys(@config.preamble.permitted_correspondence_types, 1)
          store_permitted_correspondence_types
          validate_correspondence_types
        end
      end
    end

    private

    def add_error(section_name, message)
      @errors <<  "File #{@filename} section #{section_name}: #{message}"
    end

    def  validate_is_hash(config, section, *keys)
      keys.each do |key|
        unless config.__send__(key).is_a?(RecursiveOpenStruct)
          add_error section, "Expected #{key} to be a Hash, is a #{config.__send__(key).class}"
        end
      end
    end

    def validate_correspondence_types
      validate_exact_keys(@config.correspondence_types,
                          'correspondence_types',
                          *@correspondence_types)
      @config.correspondence_types.to_hash.keys.each do |ct_key|
        validate_correspondence_type(ct_key)
      end
    end

    def validate_correspondence_type(ct_key)
      @correspondence_type  = ct_key
      ct_config = @config.correspondence_types.__send__(ct_key)
      validate_exact_keys(ct_config,
                          "correspondence_types/#{ct_key}",
                          :name,
                          :permitted_workflows,
                          :permitted_user_roles,
                          :permitted_states,
                          :workflows)
      validate_and_store_permitted_workflows(ct_config)
      validate_and_store_permitted_user_roles(ct_config)
      validate_and_store_permitted_states(ct_config)
      validate_workflows(ct_config)
    end

    def validate_and_store_permitted_workflows(ct_config)
      if ct_config.permitted_workflows.is_a?(Array)
        @permitted_workflows = ct_config.permitted_workflows.map(&:to_sym)
      else
        add_error("correspondence_types/#{@correspondence_type}/permitted_workflows",
                    "Expected an array, got #{ct_config.permitted_workflows.class}")
      end
    end

    def validate_and_store_permitted_user_roles(ct_config)
      if ct_config.permitted_user_roles.is_a?(Array)
        @permitted_user_roles = ct_config.permitted_user_roles.map(&:to_sym)
      else
        add_error("correspondence_types/#{@correspondence_type}/permitted_user_roles",
                  "Expected an array, got #{ct_config.permitted_user_roles.class}")
      end
    end

    def validate_and_store_permitted_states(ct_config)
      if ct_config.permitted_states.is_a?(Array)
        @permitted_states = ct_config.permitted_states.map(&:to_sym)
      else
        add_error("correspondence_types/#{@correspondence_type}/permitted_states",
                  "Expected an array, got #{ct_config.permitted_states.class}")
      end
    end

    def validate_workflows(ct_config)
      validate_is_hash(ct_config, "correspondence_types/#{@correspondence_type}", :workflows)
      unless ct_config.workflows.nil?
        if ct_config.workflows.is_a?(RecursiveOpenStruct)
          ct_config.workflows.to_h.keys.each do |workflow|
            @workflow = workflow
            if workflow_name_is_valid?
              validate_workflow(ct_config.workflows.__send__(workflow))
            else
              add_error("correspondence_types/#{@correspondence_type}/workflows",
                        "#{@workflow} is not a permitted workflow")
            end
          end
        end
      end
    end

    def workflow_name_is_valid?
      @workflow.in?(@permitted_workflows)
    end

    def validate_workflow(workflow_config)
      if workflow_config.is_a?(RecursiveOpenStruct)
        validate_initial_state(workflow_config)
        validate_user_roles(workflow_config)
      else
        add_error("correspondence_types/#{@correspondence_type}/workflows/#{@workflow}",
                  "Expected to be a Hash, got #{workflow_config.class}")
      end
    end

    def validate_user_roles(workflow_config)
      if workflow_config.to_h.keys.include?(:user_roles)
        if workflow_config.user_roles.is_a?(RecursiveOpenStruct)
          workflow_config.user_roles.to_h.keys.each do |user_role|
            validate_user_role(user_role, workflow_config.user_roles.__send__(user_role))
          end
        else
          add_error("correspondence_types/#{@correspondence_type}/workflows/#{@workflow}",
                    "Expected user_roles to be a Hash, got #{workflow_config.user_roles.class}")
        end
      else
        add_error("correspondence_types/#{@correspondence_type}/workflows/#{@workflow}",
                  "Missing mandatory key: user_roles")
      end
    end

    def validate_user_role(role, role_config)
      if role_config.is_a?(RecursiveOpenStruct)
        if role.in?(@permitted_user_roles)
          @role = role
          validate_user_role_keys(role_config)
        else
          add_error("correspondence_types/#{@correspondence_type}/workflows/#{@workflow}/user_roles",
                    "User role #{role} is not a permitted user role")
        end
      else
        add_error("correspondence_types/#{@correspondence_type}/workflows/#{@workflow}/user_roles",
                  "Expected #{role} to be a hash, is a #{role_config.class}")
      end
    end

    def validate_user_role_keys(role_config)
      validate_exact_keys(role_config,
                          "correspondence_types/#{@correspondence_type}/workflows/#{@workflow}/user_roles/#{@role}",
                          :states)
      states_config = role_config.states
      if states_config.present?
        if states_config.is_a?(RecursiveOpenStruct)
          validate_states(states_config)
        end
      end
    end

    def validate_states(states_config)
      states = states_config.to_h.keys
      states.each do |state|
        if state.in?(@permitted_states)
          validate_state(state, states_config)
        else
          add_error("correspondence_types/#{@correspondence_type}/workflows/#{@workflow}/user_roles/#{@role}/states/",
                   "State #{state} not a permitted state")
        end
      end
    end

    def validate_state(state, states_config)
      @state = state
      my_state_config = states_config.__send__(state)
      if my_state_config.is_a?(RecursiveOpenStruct)
        events = my_state_config.to_h.keys
        events.each do |event|
          validate_event(event, my_state_config.__send__(event))
        end
      else
        add_error("correspondence_types/#{@correspondence_type}/workflows/#{@workflow}/user_roles/#{@role}/states",
                  "Expected #{state} to be a Hash, is a #{my_state_config.class}")
      end
    end

    def validate_event(event_name, event_config)
      if event_config.is_a?(RecursiveOpenStruct) || event_config.nil?
        validate_keys_in(event_config,
                        "correspondence_types/#{@correspondence_type}/workflows/#{@workflow}/user_roles/#{@role}/states/#{@state}/#{event_name}",
                        :if,
                        :transition_to,
                        :after_transition,
                        :before_transition,
                        :switch_workflow)
      else
        add_error("correspondence_types/#{@correspondence_type}/workflows/#{@workflow}/user_roles/#{@role}/states",
          "Expected #{event_config} to be a Hash, is a #{event_config.class}")
      end
    end

    def validate_initial_state(workflow_config)
      if workflow_config.to_h.keys.include?(:initial_state)
        unless workflow_config.initial_state.to_sym.in?(@permitted_states)
          add_error("correspondence_types/#{@correspondence_type}/workflows/#{@workflow}",
                    "Initial state #{workflow_config.initial_state} is not a permitted state")
        end
      else
        add_error("correspondence_types/#{@correspondence_type}/workflows/#{@workflow}",
                  "Mandatory key :initial_state not specified")
      end
    end

    def validate_has_key?(config, key)
      key.in?(config.to_h.keys)
    end

    def store_permitted_correspondence_types
      @correspondence_types = @config.preamble.permitted_correspondence_types.to_hash.keys
    end

    def validate_exact_keys(config, section_name, *exact_keys)
      config_keys = config.to_hash.keys
      config_keys.each do |config_key|
        unless config_key.in?(exact_keys)
          add_error section_name, "Invalid key: '#{config_key}'"
        end
      end
      exact_keys.each do |exact_key|
        unless exact_key.in?(config_keys)
          add_error section_name, "Missing mandatory key: '#{exact_key}'"
        end
      end
    end

    def validate_keys_in(config, section_name, *possible_keys)
      config.to_h.keys.each do |key|
        unless key.in?(possible_keys)
          add_error section_name, "Unrecognised key: #{key}"
        end
      end
    end

    def validate_min_keys(config, min_keys)
      if config.to_hash.keys.size < min_keys
        add_error('preamble/permitted_correspondence_types',
                  "expected at least #{min_keys} entries, found #{config.to_hash.keys.size}")
      end
    end

  end
end
