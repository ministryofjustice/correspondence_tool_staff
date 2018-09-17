require 'simplecov'
SimpleCov.start

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'capybara/rspec'
require 'selenium-webdriver'

require 'rails-controller-testing'
require 'paper_trail/frameworks/rspec'

Capybara.default_max_wait_time = 4

Capybara.asset_host = 'http://localhost:3000'

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.register_driver :headless_chrome do |app|
  if ENV['CHROME_DEBUG'].present?
    configurationSetting = {}
  else
    configurationSetting = { args: %w(headless disable-gpu) }
  end

  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
      chromeOptions: configurationSetting
  )

  Capybara::Selenium::Driver.new app,
    browser: :chrome,
    desired_capabilities: capabilities
end

Capybara.javascript_driver = :headless_chrome

Capybara.server = :puma, { Silent: true }

# Set these env variables to push screenshots for failed tests to S3.
# if ENV['S3_TEST_SCREENSHOT_ACCESS_KEY_ID'].present? &&
#    ENV['S3_TEST_SCREENSHOT_SECRET_ACCESS_KEY'].present?
#   Capybara::Screenshot.s3_configuration = {
#     s3_client_credentials: {
#       access_key_id: ENV['S3_TEST_SCREENSHOT_ACCESS_KEY_ID'],
#       secret_access_key: ENV['S3_TEST_SCREENSHOT_SECRET_ACCESS_KEY'],
#       region: 'eu-west-1'
#     },
#     bucket_name: 'correspondence-staff-travis-test-failure-screenshots',
#   }
# end

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
$LOAD_PATH.unshift(File.join(File.expand_path('..', __FILE__), 'site_prism'))
require 'site_prism/page_objects/pages/application.rb'
Dir[Rails.root.join("spec/site_prism/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/site_prism/page_objects/{sections,pages}/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.include FactoryBot::Syntax::Methods
  config.include PageObjects::Pages::Application
  config.include Rails.application.routes.url_helpers


  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  [:controller, :view, :request].each do |type|
    config.include Rails::Controller::Testing::TestProcess, :type => type
    config.include Rails::Controller::Testing::TemplateAssertions, :type => type
    config.include Rails::Controller::Testing::Integration, :type => type
  end

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include Warden::Test::Helpers
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Capybara::DSL, type: :view
  config.include ViewSpecHelpers, type: :view
  config.after(:example, type: :view) do |example|
    if example.exception
      now = DateTime.now
      date_string = now.strftime('%F')
      time_string = now.strftime('%H%M%S.%3N')
      todays_dir = Rails.root.join('tmp', 'rendered-content', date_string)
      FileUtils.mkdir_p(todays_dir)

      template = example.example_group.top_level_description
      renderer = File.extname(template)
      format = File.extname(File.basename(template, renderer)).sub(/^\./, '')
      filename = "#{template.gsub(%r{[/.]}, '_')}-#{time_string}.#{format}"
      renderer.sub!(/^\./, '')
      fullpath = todays_dir.join(filename)
      File.open(fullpath, 'w') { |f| f.write response }
      puts "\033[0;33mrendered #{renderer} content: #{fullpath}\033[0m"
    end
  end

  config.include DeviseRoutingHelpers, type: :routing

  config.before(:each, type: :routing) do
    mock_warden_for_route_tests!
  end

  # Replace stubbing out CASE_UPLOADS_S3_BUCKET with a test harness of our own
  # making. The problem with stubbing out is that it doesn't work in 'before
  # :all' blocks, which are sometimes needed e.g. ICO appeals which always
  # require an uploaded document. so can't be instantiate in a 'before :all'
  self.class.__send__(:remove_const, :CASE_UPLOADS_S3_BUCKET)
  self.class.const_set(:CASE_UPLOADS_S3_BUCKET,
                       TestAWSS3.new.bucket(Settings.case_uploads_s3_bucket))

  config.before(:suite) do
    DbHousekeeping.clean(seed: true)
  end

  config.after(:suite) do
    DbHousekeeping.clean(seed: false)
  end

  config.before(:example, tag: :cli) do
    CTS.instance_variables.each { |var| CTS.remove_instance_variable var }
  end

end

def seed_database_for_tests
  FactoryBot.find_or_create :foi_correspondence_type
  FactoryBot.find_or_create :sar_correspondence_type
  FactoryBot.find_or_create :team_dacu
  FactoryBot.find_or_create :ico_correspondence_type
  FactoryBot.find_or_create :overturned_sar_correspondence_type
  FactoryBot.find_or_create :team_press_office
  FactoryBot.find_or_create :team_private_office
  FactoryBot.find_or_create :team_dacu_disclosure
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

SitePrism.configure do |config|
  config.use_implicit_waits = true
end
