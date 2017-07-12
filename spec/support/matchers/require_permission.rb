require 'rspec/expectations'

RSpec::Matchers.define :require_permission do |permission|
  match do |event_or_block|
    if event_or_block.respond_to? :call
      policy = instance_double(CasePolicy)
      allow(policy).to receive(permission)
                         .with(no_args) { @permission_received = true }
      if @with_args
        expect(CasePolicy).to receive(:new).with(*@with_args).and_return(policy)
      else
        expect(CasePolicy).to receive(:new).and_return(policy)
      end
      expect do
        event_or_block.call
      end .not_to raise_error
    else
      expect_any_instance_of(CasePolicy).to receive(permission).and_return(true)
      event_or_block[:callbacks][:guards].each do |guard|
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
    @with_args = args
  end

  supports_block_expectations
end
