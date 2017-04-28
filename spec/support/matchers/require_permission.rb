require 'rspec/expectations'

RSpec::Matchers.define :require_permission do |permission|
  match do |event|
    expect_any_instance_of(CasePolicy).to receive(permission).and_return(true)
    event[:callbacks][:guards].each do |guard|
      expect do
        guard.call(@object, nil, @options)
        @permission_received = true
      end .not_to raise_error
    end
  end

  chain :using_options do |options|
    @options = options
  end

  chain :using_object do |object|
    @object = object
  end
end
