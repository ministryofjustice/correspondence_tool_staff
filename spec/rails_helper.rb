require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/poltergeist'
require 'rails-controller-testing'

Capybara.javascript_driver = :poltergeist

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

      renderer = File.extname(subject)
      format = File.extname(File.basename(subject, renderer)).sub(/^\./, '')
      filename = "#{subject.gsub(%r{[/.]}, '_')}-#{time_string}.#{format}"
      renderer.sub!(/^\./, '')
      fullpath = todays_dir.join(filename)
      File.open(fullpath, 'w') { |f| f.write response }
      puts "\033[0;33mrendered #{renderer} content: #{fullpath}\033[0m"
    end
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
