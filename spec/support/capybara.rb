Webdrivers.cache_time = 86_400
Capybara.default_max_wait_time = 4

=begin
Capybara.register_driver :firefox do |app|
  Capybara::Selenium::Driver.new(app, browser: :firefox)
end
=end

Capybara.register_driver :remote_selenium do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument("--window-size=1400,1400")

  Capybara::Selenium::Driver.new(
    app,
    url: "http://#{ENV["SELENIUM_HOST"]}:4444/wd/hub",
    browser: :firefox,
    capabilities: options
  )
end

Capybara.register_driver :remote_selenium_headless do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument("--headless")
  options.add_argument("--window-size=1400,1400")

  Capybara::Selenium::Driver.new(
    app,
    url: "http://#{ENV["SELENIUM_HOST"]}:4444/wd/hub",
    browser: :firefox,
    capabilities: options
  )
end

Capybara.register_driver :local_selenium do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--window-size=1400,1400")

  Capybara::Selenium::Driver.new(app, browser: :chrome, capabilities: options)
end

Capybara.register_driver :local_selenium_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless")
  options.add_argument("--window-size=1400,1400")

  Capybara::Selenium::Driver.new(app, browser: :chrome, capabilities: options)
end

selenium_app_host = ENV.fetch("SELENIUM_APP_HOST") do
  IPSocket.getaddress('app')
end

Capybara.configure do |config|
  config.default_driver = :firefox
  config.server = :puma, { Silent: true }
  config.server_host = '0.0.0.0'
  config.server_port = 3000
end

RSpec.configure do |config|
  config.before(:each, type: :feature) do |example|
    # `Capybara.app_host` is reset in the RSpec before_setup callback defined
    # in `ActionDispatch::SystemTesting::TestHelpers::SetupAndTeardown`, which
    # is annoying as hell, but not easy to "fix". Just set it manually every
    # test run.
    Capybara.app_host = "http://#{selenium_app_host}:3000"

    # Allow Capybara and WebDrivers to access network if necessary
    driver = if example.metadata[:js]
               locality = ENV["SELENIUM_HOST"].present? ? "remote" : "local"
               headless = "_headless" if ENV["DISABLE_HEADLESS"].blank?

               "#{locality}_selenium#{headless}".to_sym
             else
               :rack_test
             end

    Capybara.default_driver = driver
    Capybara.javascript_driver = driver
  end
end
