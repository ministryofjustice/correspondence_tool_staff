module ConfigurableStateMachine
  class ConfigValidator
    attr_reader :errors

    def initialize(config, filename)
      @filename = filename
      @config = config
      @case_types = []
      @permitted_workflows = []
      @permitted_user_roles = []
      @permitted_states = []
      @errors = []
    end

    def run
      check_for_dupe_keys
      validate_configs
      if errors.any?
        raise ConfigurationError, @errors
      end
    end

    def validate_configs
      validate_exact_keys(@config, "root", :preamble, :case_types)
      validate_is_hash(@config, "root", :preamble, :case_types)
      if @config.preamble.present? && @config.preamble.is_a?(RecursiveOpenStruct)
        validate_exact_keys(@config.preamble,
                            "preamble",
                            :organisation,
                            :organisation_abbreviation,
                            :permitted_case_types)
        process_permitted_case_types(@config.preamble)
        validate_case_types
      end
    end

  private

    def check_for_dupe_keys
      detector = DuplicateKeyDetector.new(@filename)
      detector.run
      if detector.dupes?
        raise ConfigurationError, detector.dupe_details
      end
    end

    def add_error(section_name, message)
      @errors << "File #{@filename} section #{section_name}: #{message}"
    end

    def validate_is_hash(config, section, *keys)
      keys.each do |key|
        unless config.__send__(key).is_a?(RecursiveOpenStruct)
          add_error section, "Expected #{key} to be a Hash, is a #{config.__send__(key).class}"
        end
      end
    end

    def validate_case_types
      validate_exact_keys(@config.case_types,
                          "case_types",
                          *@case_types)
      @config.case_types.to_hash.each_key do |case_type_key|
        validate_case_type(case_type_key)
      end
    end

    def validate_case_type(case_type_key)
      ct_config = @config.case_types.__send__(case_type_key)
      validate_exact_keys(ct_config,
                          "case_types/#{case_type_key}",
                          :name,
                          :permitted_workflows,
                          :permitted_user_roles,
                          :permitted_states,
                          :workflows)
      process_permitted_workflows(case_type_name: case_type_key, case_type_config: ct_config)
      process_permitted_user_roles(case_type_name: case_type_key, case_type_config: ct_config)
      process_permitted_states(case_type_name: case_type_key, case_type_config: ct_config)
      validate_workflows(case_type_name: case_type_key, case_type_config: ct_config)
    end

    def process_permitted_workflows(case_type_name:, case_type_config:)
      if case_type_config.permitted_workflows.is_a?(Array)
        @permitted_workflows = case_type_config.permitted_workflows.map(&:to_sym)
      else
        add_error("case_types/#{case_type_name}/permitted_workflows",
                  "Expected an array, got #{case_type_config.permitted_workflows.class}")
      end
    end

    def process_permitted_user_roles(case_type_name:, case_type_config:)
      if case_type_config.permitted_user_roles.is_a?(Array)
        @permitted_user_roles = case_type_config.permitted_user_roles.map(&:to_sym)
      else
        add_error("case_types/#{case_type_name}/permitted_user_roles",
                  "Expected an array, got #{case_type_config.permitted_user_roles.class}")
      end
    end

    def process_permitted_states(case_type_name:, case_type_config:)
      if case_type_config.permitted_states.is_a?(Array)
        @permitted_states = case_type_config.permitted_states.map(&:to_sym)
      else
        add_error("case_types/#{case_type_name}/permitted_states",
                  "Expected an array, got #{case_type_config.permitted_states.class}")
      end
    end

    def validate_workflows(case_type_name:, case_type_config:)
      validate_is_hash(case_type_config, "case_types/#{case_type_name}", :workflows)
      if !case_type_config.workflows.nil? && case_type_config.workflows.is_a?(RecursiveOpenStruct)
        case_type_config.workflows.to_h.each_key do |workflow|
          if workflow_name_is_valid?(workflow_name: workflow)
            validate_workflow(case_type_name:,
                              workflow_name: workflow,
                              workflow_config: case_type_config.workflows.__send__(workflow))
          else
            add_error("case_types/#{case_type_name}/workflows",
                      "#{workflow} is not a permitted workflow")
          end
        end
      end
    end

    def workflow_name_is_valid?(workflow_name:)
      workflow_name.in?(@permitted_workflows)
    end

    def validate_workflow(case_type_name:, workflow_name:, workflow_config:)
      if workflow_config.is_a?(RecursiveOpenStruct)
        validate_initial_state(case_type_name:,
                               workflow_name:,
                               workflow_config:)
        validate_user_roles(case_type_name:,
                            workflow_name:,
                            workflow_config:)
      else
        add_error("case_types/#{case_type_name}/workflows/#{workflow_name}",
                  "Expected to be a Hash, got #{workflow_config.class}")
      end
    end

    def validate_user_roles(case_type_name:, workflow_name:, workflow_config:)
      if workflow_config.to_h.keys.include?(:user_roles)
        if workflow_config.user_roles.is_a?(RecursiveOpenStruct)
          workflow_config.user_roles.to_h.each_key do |user_role|
            validate_user_role(case_type_name:,
                               workflow_name:,
                               user_role:,
                               user_role_config: workflow_config.user_roles.__send__(user_role))
          end
        else
          add_error("case_types/#{case_type_name}/workflows/#{workflow_name}",
                    "Expected user_roles to be a Hash, got #{workflow_config.user_roles.class}")
        end
      else
        add_error("case_types/#{case_type_name}/workflows/#{workflow_name}",
                  "Missing mandatory key: user_roles")
      end
    end

    def validate_user_role(case_type_name:, workflow_name:, user_role:, user_role_config:)
      if user_role_config.is_a?(RecursiveOpenStruct)
        if user_role.in?(@permitted_user_roles)
          validate_user_role_keys(case_type_name:,
                                  workflow_name:,
                                  user_role:,
                                  user_role_config:)
        else
          add_error("case_types/#{case_type_name}/workflows/#{workflow_name}/user_roles",
                    "User role #{user_role} is not a permitted user role")
        end
      else
        add_error("case_types/#{case_type_name}/workflows/#{workflow_name}/user_roles",
                  "Expected #{user_role} to be a hash, is a #{user_role_config.class}")
      end
    end

    def validate_user_role_keys(case_type_name:, workflow_name:, user_role:, user_role_config:)
      validate_exact_keys(user_role_config,
                          "case_types/#{case_type_name}/workflows/#{workflow_name}/user_roles/#{user_role}",
                          :states)
      states_config = user_role_config.states
      if states_config.present? && states_config.is_a?(RecursiveOpenStruct)
        validate_states(case_type_name:,
                        workflow_name:,
                        user_role:,
                        states_config:)
      end
    end

    def validate_states(case_type_name:, workflow_name:, user_role:, states_config:)
      states = states_config.to_h.keys
      states.each do |state|
        if state.in?(@permitted_states)
          validate_state(case_type_name:,
                         workflow_name:,
                         user_role:,
                         state_name: state, states_config:)
        else
          add_error("case_types/#{case_type_name}/workflows/#{workflow_name}/user_roles/#{user_role}/states/",
                    "State #{state} not a permitted state")
        end
      end
    end

    def validate_state(case_type_name:, workflow_name:, user_role:, state_name:, states_config:)
      my_state_config = states_config.__send__(state_name)
      if my_state_config.is_a?(RecursiveOpenStruct)
        events = my_state_config.to_h.keys
        events.each do |event|
          validate_event(case_type_name:,
                         workflow_name:,
                         user_role:,
                         state_name:,
                         event_name: event,
                         event_config: my_state_config.__send__(event))
        end
      else
        add_error("case_types/#{case_type_name}/workflows/#{workflow_name}/user_roles/#{user_role}/states",
                  "Expected #{state_name} to be a Hash, is a #{my_state_config.class}")
      end
    end

    def validate_event(case_type_name:, workflow_name:, user_role:, state_name:, event_name:, event_config:)
      if event_config.is_a?(RecursiveOpenStruct) || event_config.nil?
        path = "case_types/#{case_type_name}/workflows/#{workflow_name}/user_roles/#{user_role}/states/#{state_name}/#{event_name}"
        validate_keys_in(event_config,
                         path,
                         :if,
                         :transition_to,
                         :transition_to_using,
                         :after_transition,
                         :before_transition,
                         :switch_workflow,
                         :switch_workflow_using)
        validate_predicate_config(event_config, path)
        validate_switch_workflow_config(event_config, workflow_name, path)
        validate_switch_workflow_using_config(event_config, path)
        validate_transition_to_using_config(event_config, path)
        validate_after_transition_config(event_config, path)
      else
        add_error("case_types/#{case_type_name}/workflows/#{workflow_name}/user_roles/#{user_role}/states",
                  "Expected #{event_config} to be a Hash, is a #{event_config.class}")
      end
    end

    def validate_initial_state(case_type_name:, workflow_name:, workflow_config:)
      if workflow_config.to_h.keys.include?(:initial_state)
        unless workflow_config.initial_state.to_sym.in?(@permitted_states)
          add_error("case_types/#{case_type_name}/workflows/#{workflow_name}",
                    "Initial state #{workflow_config.initial_state} is not a permitted state")
        end
      else
        add_error("case_types/#{case_type_name}/workflows/#{workflow_name}",
                  "Mandatory key :initial_state not specified")
      end
    end

    def validate_has_key?(config, key)
      key.in?(config.to_h.keys)
    end

    def process_permitted_case_types(preamble)
      validate_min_keys(preamble.permitted_case_types, "preamble/permitted_case_types", 1)
      @case_types = preamble.permitted_case_types.to_hash.keys
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
      config.to_h.each_key do |key|
        unless key.in?(possible_keys)
          add_error section_name, "Unrecognised key: #{key}"
        end
      end
    end

    def validate_min_keys(config, section_name, min_keys)
      if config.to_hash.keys.size < min_keys
        add_error(section_name,
                  "expected at least #{min_keys} entries, found #{config.to_hash.keys.size}")
      end
    end

    def validate_transition_to_using_config(event_config, path)
      if event_config && event_config.transition_to_using.present?
        result = validate_conditonal_transition_method(event_config.transition_to_using)
        unless result.nil?
          add_error(path, result)
        end
      end
    end

    def validate_switch_workflow_using_config(event_config, path)
      if event_config && event_config.switch_workflow_using.present?
        result = validate_conditonal_transition_method(event_config.switch_workflow_using)
        unless result.nil?
          add_error(path, result)
        end
      end
    end

    def validate_conditonal_transition_method(conditional_transition_method)
      validate_class_and_method(conditional_transition_method)
    end

    def validate_predicate_config(event_config, path)
      if event_config && event_config.if.present?
        result = validate_predicate_method(event_config.if)
        unless result.nil?
          add_error(path, result)
        end
      end
    end

    def validate_predicate_method(predicate)
      validate_class_and_method(predicate)
    end

    def validate_class_and_method(class_and_method)
      result = nil
      klass, method = class_and_method.split("#")
      if method.nil?
        result = "Invalid predicate or conditional: #{class_and_method}"
      elsif klass.safe_constantize.nil?
        result = "No such class: #{klass}"
      else
        unless klass.constantize.instance_methods.include?(method.to_sym)
          result = "No such instance method '#{method}' on class #{klass}"
        end
      end
      result
    end

    def validate_after_transition_config(event_config, path)
      if event_config && event_config.after_transition.present?
        result = validate_predicate_method(event_config.after_transition)
        unless result.nil?
          add_error(path, result)
        end
      end
    end

    def validate_switch_workflow_config(event_config, current_workflow, path)
      if event_config && event_config.switch_workflow.present?
        result = validate_switch_workflow_param(event_config, current_workflow, path)
        unless result.nil?
          add_error(path, result)
        end
      end
    end

    def validate_switch_workflow_param(event_config, current_workflow, path)
      new_workflow = event_config.switch_workflow.to_sym
      if new_workflow == current_workflow
        add_error(path, "Cannot switch workflow to the current workflow")
      end
      unless new_workflow.in?(@permitted_workflows)
        add_error(path, "Invalid workflow: #{new_workflow}")
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
