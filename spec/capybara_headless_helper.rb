Capybara.asset_host = 'http://localhost:3000'

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  unless ENV["CHROME_DEBUG"]
    options.add_argument('--headless')
    options.add_argument('--disable-gpu')
    options.add_argument('--no-sandbox')
    options.add_argument('--start-maximized')
    options.add_argument('--window-size=1980,2080')
    options.add_argument('--enable-features=NetworkService,NetworkServiceInProcess')
  end

  Capybara::Selenium::Driver.new(app, browser: :chrome, capabilities: options)

end

Capybara.javascript_driver = :headless_chrome

