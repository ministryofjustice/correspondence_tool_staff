require 'rspec/expectations'

RSpec::Matchers.define :require_permission do |permission|
  @permission_result = true

  match do |event_or_block|
    if event_or_block.respond_to? :call
      policy_class = Pundit::PolicyFinder.new(@object).policy!
      policy = spy(policy_class)
      allow(policy).to receive(permission)
                         .with(no_args) do
                           @permission_received = true
                           @permission_result
                         end
      allowing = @allowing || []
      allowing.each do |allow_permission|
        allow(policy).to receive(allow_permission).and_return(true)
      end
      disallowing = @disallowing || []
      disallowing.each do |disallow_permission|
        allow(policy).to receive(disallow_permission).and_return(false)
      end
      if @with_args.present?
        allow(policy_class).to receive(:new).with(*@with_args).and_return(policy)
      else
        allow(policy_class).to receive(:new).and_return(policy)
      end
      event_or_block.call
      expect(@permission_received).to eq true
    else
      policy_class = Pundit::PolicyFinder.new(@object).policy!
      expect_any_instance_of(policy_class).to receive(permission)
                                                .and_return(@permission_result)
      state_machine_class = RSpec::current_example
                              .example_group
                              .top_level_description
                              .constantize
      event = state_machine_class.events[event_or_block]
      event[:callbacks][:guards].each do |guard|
        expect do
          guard.call(@object, nil, @options)
          @permission_received = true
        end .not_to raise_error
      end
    end
    expect(@permission_received).to eq true
  end

  chain :using_options do |options|
    @options = options
  end

  chain :using_object do |object|
    @object = object
  end

  chain :with_args do |*args|
    @object = args.second
    @with_args = args
  end

  chain :allowing do |*args|
    @allowing ||= Set.new
    @allowing += args
    @disallowing ||= Set.new
    @disallowing -= args
  end

  chain :disallowing do |*args|
    @disallowing ||= Set.new
    @disallowing += args
    @allowing ||= Set.new
    @allowing -= args
  end

  chain :disallow do
    @permission_result = false
  end

  supports_block_expectations
end
