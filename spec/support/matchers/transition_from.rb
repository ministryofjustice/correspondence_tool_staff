require 'rspec/expectations'

RSpec::Matchers.define :transition_from do |from_state|
  match do |event|
    expect(event[:transitions]).to have_key from_state.to_s
    expect(event[:transitions][from_state.to_s]).to include @to_state
  end

  chain :to do |to_state|
    @to_state = to_state.to_s
  end
end
