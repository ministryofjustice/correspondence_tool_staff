
# This singleton class manages the reading of the state machine config files and instantiation of
# an Organisational state machine for each file read.
#
# Call by:
#   ConfigurableStateMachine::Manager.instance(config_dir)
#

module ConfigurableStateMachine
  class Manager
    # include Singleton

    @@instance = nil

    DEFAULT_CONFIG_DIR = File.join(Rails.root, 'config', 'state_machine')

    attr_reader :config_dir

    def initialize(config_dir)
      @config_dir = config_dir
      @errors = []
      @state_machines = RecursiveOpenStruct.new
      Dir[File.join(config_dir, '*.yml')].each do |config_file|
        config = RecursiveOpenStruct.new(YAML.load_file(config_file))
        ConfigValidator.new(config, config_file).run
        org = config.preamble.organisation_abbreviation
        @state_machines[org] = config
      end
    end

    def self.instance(config_dir = DEFAULT_CONFIG_DIR)
      if @@instance.nil? || @@instance.config_dir != config_dir
        @@instance = __send__(:new, config_dir)
      end
      @@instance
    end

    private_class_method :new


    def state_machine(org:, case_type:, workflow:, kase:)
      workflow_config = @state_machines[org].case_types[case_type].workflows[workflow]
      Machine.new(config: workflow_config, kase: kase)
    end

  end
end
