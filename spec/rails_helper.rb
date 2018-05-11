require 'simplecov'
SimpleCov.start

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/poltergeist'
require 'rails-controller-testing'
require 'paper_trail/frameworks/rspec'


Capybara.javascript_driver = :poltergeist
# Capybara.register_driver :poltergeist do |app|
#   Capybara::Poltergeist::Driver.new(app,
#                                     js_errors: true,
#                                     phantomjs_logger: STDERR,
#                                     inspector: true)
# end


# Set these env variables to push screenshots for failed tests to S3.
if ENV['S3_TEST_SCREENSHOT_ACCESS_KEY_ID'].present? &&
   ENV['S3_TEST_SCREENSHOT_SECRET_ACCESS_KEY'].present?
  Capybara::Screenshot.s3_configuration = {
    s3_client_credentials: {
      access_key_id: ENV['S3_TEST_SCREENSHOT_ACCESS_KEY_ID'],
      secret_access_key: ENV['S3_TEST_SCREENSHOT_SECRET_ACCESS_KEY'],
      region: 'eu-west-1'
    },
    bucket_name: 'correspondence-staff-travis-test-failure-screenshots',
  }
end

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
Dir[Rails.root.join("spec/site_prism/page_objects/{sections,pages}/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.include FactoryGirl::Syntax::Methods
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

  config.before(:each) do
    # This mock appears to get triggered if you try to do:
    #
    #    allow_any_instance_of(Case).to receive(...)
    #
    # because somewhow this triggers a call os object on
    # CASE_UPLOADS_S3_BUCKET. If we can't resolve this then we may have to
    # change/remove the safeguard below.
    #
    # The relevant bits of the backtrace:
    #
    # #0  block (3 levels) in block (3 levels) in <top (required)> at /Users/michaelgorodnitzky/Code/cts/spec/rails_helper.rb:106
    # ... rspec stuff ...
    #  #7  block (2 levels) in #<Class:#<Aws::S3::Bucket:0x007fe706aa96d8>>.block (2 levels) in define_proxy_method(*args#Array, &block#NilClass) at /Users/michaelgorodnitzky/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/rspec-mocks-3.5.0/lib/rspec/mocks/method_double.rb:64
    #  #8  Draper::Decoratable::ClassMethods.===(other#Aws::S3::Bucket) at /Users/michaelgorodnitzky/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/draper-3.0.0.pre1/lib/draper/decoratable.rb:89
    #  #9  block in RSpec::Mocks::Space.block in proxies_of(klass#Class) at /Users/michaelgorodnitzky/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/rspec-mocks-3.5.0/lib/rspec/mocks/space.rb:108
    # ... rspec stuff ...
    allow(CASE_UPLOADS_S3_BUCKET)
      .to receive(:object).and_raise("This test requires stubbing of S3Uploader or CASE_UPLOADS_S3_BUCKET methods. Don't actually care what S3 responses you get? Use 'stub_s3_uploader_for_all_files!' in your test(s).")
    allow(CASE_UPLOADS_S3_BUCKET)
      .to receive(:objects).and_raise("This test requires stubbing of S3Uploader or CASE_UPLOADS_S3_BUCKET methods. Don't actually care what S3 responses you get? Use 'stub_s3_uploader_for_all_files!' in your test(s).")
  end

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
  FactoryGirl.find_or_create :foi_correspondence_type
  FactoryGirl.find_or_create :sar_correspondence_type
  FactoryGirl.find_or_create :team_dacu
  FactoryGirl.find_or_create :team_press_office
  FactoryGirl.find_or_create :team_private_office
  FactoryGirl.find_or_create :team_dacu_disclosure
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
