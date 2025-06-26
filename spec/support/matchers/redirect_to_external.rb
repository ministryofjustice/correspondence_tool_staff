require "rspec/expectations"

RSpec::Matchers.define :redirect_to_external do |url|
  description { "redirect to #{url}" }

  match do |code|
    code.call
  rescue ActionController::RoutingError
    expect(current_url).to eq url.to_s
  end

  supports_block_expectations
end
