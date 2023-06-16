module DeviseRoutingHelpers
  # workaround for this issue https://github.com/plataformatec/devise/issues/1670
  def mock_warden_for_route_tests!
    warden = double("warden")
    allow_any_instance_of(ActionDispatch::Request)
      .to receive(:env).and_wrap_original do |orig, *args|
      env = orig.call(*args)
      env["warden"] = warden
      env
    end
    allow(warden).to receive(:authenticate!).and_return(true)
    # allow(warden).to receive(:user).with(:user).and_return(authenticated_user)
  end
end
