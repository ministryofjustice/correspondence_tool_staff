require "rspec/expectations"

RSpec::Matchers.define :have_no_permitted_events do
  match do |controller|
    controller.instance_variable_get(:@permitted_events) == []
  end
  failure_message do |actual|
    "expected permitted_events to be empty, was #{actual.instance_variable_get(:@permitted_events).inspect}"
  end
end

RSpec::Matchers.define :have_permitted_events do |*events|
  match do |controller|
    controller.instance_variable_get(:@permitted_events) == events
  end

  failure_message do |actual|
    "expected permitted_events to be #{events}, was #{actual.instance_variable_get(:@permitted_events).inspect}"
  end
end

RSpec::Matchers.define :have_permitted_events_including do |*args|
  match do |controller|
    (args - controller.instance_variable_get(:@permitted_events)).empty?
  end
  failure_message do |actual|
    "expected permitted_events to include #{args.inspect}, was #{actual.instance_variable_get(:@permitted_events).inspect}"
  end
end

RSpec::Matchers.define :have_nil_permitted_events do
  match do |controller|
    controller.instance_variable_get(:@permitted_events).nil?
  end
  failure_message do |actual|
    "expected permitted_events to be nil, was #{actual.instance_variable_get(:@permitted_events.inspect)}"
  end
end
