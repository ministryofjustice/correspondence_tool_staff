unless ENV["COVERAGE"].nil?
  require "simplecov"
  require "simplecov-json"

  if ENV["CI"]
    SimpleCov.formatter = SimpleCov::Formatter::SimpleFormatter
  else
    SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::JSONFormatter,
    ])
  end

  SimpleCov.start "rails" do
    add_group "Services", "app/services"
    add_group "Policies", "app/policies"
    add_group "Decorators", "app/decorators"
    add_group "Validators", "app/validators"
    # application doesn't use action cable
    add_filter "/app/channels/"
    # all emails (including devise ones) get sent via gov.uk notify service
    add_filter "/app/mailers/application_mailer.rb"
    add_filter "/lib/"
  end
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require "spec_helper"
require File.expand_path("../config/environment", __dir__)
require "rspec/rails"
require "capybara/rails"
# Add additional requires below this line. Rails is not loaded until this point!
require "capybara/rspec"
require "rails-controller-testing"
require "paper_trail/frameworks/rspec"

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_preference(:download, { prompt_for_download: false, default_directory: DownloadHelpers::PATH.to_s })

  unless ENV["CHROME_DEBUG"]
    options.add_argument("--disable-gpu")
    options.add_argument("--enable-features=NetworkService,NetworkServiceInProcess")
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--start-maximized")
    options.add_argument("--window-size=1980,2080")
  end

  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

Capybara.default_max_wait_time = 1
Capybara.asset_host = "http://localhost:3000"
Capybara.server = :puma, { Silent: true }
Capybara.javascript_driver = :headless_chrome

# Force Timecop Thread Safety to prevent intermittent date related issues during
# parallel tests. Ensure all Timecop usage in tests are in
# Timecop.freeze do...end blocks
Timecop.safe_mode = true

# include missing module because of load order issues on CI
require Rails.root.join("spec/support/features/interactions/overturned_ico.rb")

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
$LOAD_PATH.unshift(File.join(File.expand_path(__dir__), "site_prism"))
require "site_prism/page_objects/pages/application"

# include linked_cases_section specifically to avoid machine-specific load order issues
require "site_prism/page_objects/sections/cases/linked_cases_section"
require "site_prism/page_objects/sections/cases/case_attachment_section"

Dir[Rails.root.join("spec/site_prism/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/site_prism/page_objects/sections/shared/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/site_prism/page_objects/sections/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/site_prism/page_objects/pages/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [Rails.root.join("spec/fixtures")]
  config.include FactoryBot::Syntax::Methods
  config.include PageObjects::Pages::Application
  config.include Rails.application.routes.url_helpers

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  %i[controller view request].each do |type|
    config.include(Rails::Controller::Testing::TestProcess, type:)
    config.include(Rails::Controller::Testing::TemplateAssertions, type:)
    config.include Rails::Controller::Testing::Integration, type:
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
      now = Time.zone.now
      date_string = now.strftime("%F")
      time_string = now.strftime("%H%M%S.%3N")
      todays_dir = Rails.root.join("tmp", "rendered-content", date_string)
      FileUtils.mkdir_p(todays_dir)

      template = example.example_group.top_level_description
      renderer = File.extname(template)
      format = File.extname(File.basename(template, renderer)).sub(/^\./, "")
      filename = "#{template.gsub(%r{[/.]}, '_')}-#{time_string}.#{format}"
      renderer.sub!(/^\./, "")
      fullpath = todays_dir.join(filename)
      File.open(fullpath, "w") { |f| f.write response }
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
  # require an uploaded document. so cannot be instantiated in a 'before :all'
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

  # Automatically reset Date/Time/DateTime to prevent issues
  # during CI builds
  config.after(:all) do
    Timecop.return
  end
end

def seed_database_for_tests
  FactoryBot.find_or_create :foi_correspondence_type
  FactoryBot.find_or_create :sar_correspondence_type
  FactoryBot.find_or_create :sar_internal_review_correspondence_type
  FactoryBot.find_or_create :offender_sar_correspondence_type
  FactoryBot.find_or_create :offender_sar_complaint_correspondence_type
  FactoryBot.find_or_create :team_dacu
  FactoryBot.find_or_create :team_branston
  FactoryBot.find_or_create :ico_correspondence_type
  FactoryBot.find_or_create :overturned_sar_correspondence_type
  FactoryBot.find_or_create :overturned_foi_correspondence_type
  FactoryBot.find_or_create :team_dacu_disclosure
  FactoryBot.find_or_create :disclosure_bmt_user
  FactoryBot.find_or_create :disclosure_specialist
  FactoryBot.find_or_create :foi_responder
  FactoryBot.find_or_create :sar_responder
  FactoryBot.find_or_create :default_press_officer
  FactoryBot.find_or_create :default_private_officer
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
