class EventTransitions
  attr_reader :machine, :event_name, :from, :to

  def initialize(machine, event_name, &block)
    @machine    = machine
    @event_name = event_name
    instance_eval(&block)
  end

  # rubocop:disable Metrics/ParameterLists
  def transition(from: nil, to: nil, guard: nil, policy: nil, new_workflow: nil,
                 authorize: nil)
    unless policy.nil?
      raise RuntimeError, 'The "policy" option for state machine transition is deprecated, use "authorize".'
    end

    @from = to_s_or_nil(from)
    @to = to_s_or_nil(to)

    machine.transition(from: @from, to: @to)

    guards = []
    guards << guard if guard

    if authorize.present?
      guards << make_policy_checker(authorize)
    elsif @authorize.present?
      guards << make_policy_checker(@authorize)
    end

    transition = {
      state: @to,
      guards: guards
    }
    transition[:new_workflow] = new_workflow if new_workflow.present?
    machine.events[event_name][:transitions][@from] << transition
  end
  # rubocop:enable Metrics/ParameterLists

  def guard(&block)
    add_callback(callback_type: :guards, &block)
  end

  def authorize(policy)
    @authorize = policy || "#{@event_name}?"
  end

  def authorize_each_transition
    authorize true
  end

  def authorize_by_event_name
    authorize "#{@event_name}?"
  end

  private

  def add_callback(callback_type: nil, &block)
    validate_callback_type_and_class(callback_type)

    machine.events[event_name][:callbacks][callback_type] << block
  end

  def validate_callback_type_and_class(callback_type)
    if callback_type.nil?
      raise ArgumentError.new("missing keyword: callback_type")
    end
  end

  def to_s_or_nil(input)
    input.nil? ? input : input.to_s
  end

  def array_to_s_or_nil(input)
    Array(input).map { |item| to_s_or_nil(item) }
  end

  def make_policy_checker(authorize)
    policy = if authorize == true
               "#{@event_name}_from_#{@from}_to_#{@to}?"
             else
               authorize
             end

    if authorize
      lambda do |kase, _last_transition, options|
        user = options.key?(:acting_user) ? options[:acting_user] : User.find(options[:acting_user_id])

        policy_object = Pundit.policy!(user, kase)
        if policy_object.respond_to? policy
          policy_object.__send__ policy
        else
          raise NameError.new("Policy \"#{policy}\" does not exist.")
        end
      end
    else
      lambda { |_kase, _last_transition, _options| true }
    end
  end
end
