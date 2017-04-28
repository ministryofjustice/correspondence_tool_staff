require 'rspec/expectations'

RSpec::Matchers.define :trigger_the_event do |event|
  match do |code|
    allow(@state_machine).to receive(:trigger!)
    code.call
    expect(@state_machine)
      .to have_received(:trigger!).with(
            event,
            @parameters.merge({ event: event }),
          )
  end

  chain :on_state_machine do |state_machine|
    @state_machine = state_machine
  end

  chain :with_parameters do |params|
    @parameters = params
  end

  supports_block_expectations

  failure_message do |_code|
    "expected #{@state_machine} to have received trigger!(#{event}, #{@parameters.merge({event: event})})"
  end
end
