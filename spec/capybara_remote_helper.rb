Capybara.app_host = "http://#{IPSocket.getaddress(Socket.gethostname)}:3000"

# Set the host and port
Capybara.server_host = '0.0.0.0'
Capybara.server_port = '3000'

# Add a configuration to connect to Chrome remotely through Selenium Grid
Capybara.register_driver :remote_selenium do |app|
  # Pass our arguments to run headless
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--window-size=1400,1400")

  # and point capybara at our chromium docker container
  Capybara::Selenium::Driver.new(
      app,
      browser: :remote,
      url: "http://chrome:4444/wd/hub",
      capabilities: options,
    )
end

# set the capybara driver configs
Capybara.javascript_driver = :remote_selenium
Capybara.default_driver = :remote_selenium

# This will force capybara to include the port in requests
Capybara.always_include_port = true

# This configures the system tests
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :remote_selenium
  end
end
