module DeviseRoutingHelpers
  # workaround for this issue https://github.com/plataformatec/devise/issues/1670
  def mock_warden_for_route_tests!
    warden = instance_double("warden")
    allow_any_instance_of(ActionDispatch::Request) # rubocop:disable RSpec/AnyInstance
      .to receive(:env).and_wrap_original do |orig, *args|
      env = orig.call(*args)
      env["warden"] = warden
      env
    end
    allow(warden).to receive(:authenticate!).and_return(true)
  end
end
