source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'activerecord-session_store'
gem 'acts_as_tree', '~> 2.9'
# Gems to help generating with Excel spreadsheets
# undeclared (but documented) dependency on rubyzip
# This is from the readme of axlsx_rails.
gem 'rubyzip', '>= 1.2.4'
gem 'caxlsx'
gem 'caxlsx_rails'
# AXLSX styler - easy styling of cells based on cell references
gem 'axlsx_styler'
gem 'awesome_print'
gem 'aws-sdk', '2.7.3'
gem 'bank_holiday', git: 'https://github.com/ministryofjustice/bank_holiday.git', branch: 'bundler-fix'
gem 'business_time'
gem 'config', '~> 2.0'
gem 'devise', '~> 4.7.1'
gem 'draper', '4.0.1'
gem 'dropzonejs-rails', '>= 0.8'
gem 'foreman', '~> 0.87.1'
gem 'factory_bot_rails', '~> 5.1.1'
gem 'faker', '~> 2.10.2'
gem 'gov_uk_date_fields', '~> 3.1'
gem 'govuk_template',         '~> 0.26.0'
gem 'govuk_frontend_toolkit', '>= 9.0.0'
gem 'govuk_elements_rails',   '>= 3.1.2'
gem 'govuk_elements_form_builder', '>= 1.2.0'
gem 'govuk_notify_rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'humanize_boolean'
gem 'jbuilder', '~> 2.10'
gem 'jquery-rails', '~> 4.3.5'
gem 'jquery-ui-rails'
gem 'jsonb_accessor', '~> 1.0.0.beta.1'
gem 'kaminari'
gem 'libreconv', '~> 0.9.5'
gem 'logstash-event'
gem 'lograge'
gem 'loofah', '>= 2.3.1'
gem 'mechanize', '>= 2.7.5'
gem 'mimetype-fu', '~> 0.1.2'
gem 'paper_trail', '~> 10.3'
gem 'pg', '~> 1.2'
gem 'pg_search', '~> 2.3.0'
gem 'pry-rails'
gem 'puma', '~> 4.3'
gem 'pundit', '~>2.1'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.4', '>= 5.2.4.2'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

gem 'rails-data-migrations', '~> 1.2.0'
gem 'recursive-open-struct'
gem 'sablon'
gem 'sass-rails', '~> 6.0'
gem 'sentry-raven', '~> 2.12.3'
gem 'slim-rails', '~> 3.2'
gem 'shell-spinner'
gem 'schema_plus_enums', '~> 0.1'
gem 'sidekiq', '~> 6.0.6'

gem 'table_print'
# gem 'thor-rails'
gem 'timecop'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

group :test do
  gem 'capybara', '~> 3.29.0'
  gem 'codeclimate-test-reporter', '~> 1.0'
  gem 'i18n-tasks', '~> 0.9.30'
  gem 'rails-controller-testing', require: false
  gem 'shoulda-matchers', '~> 4.3'
  gem 'site_prism', '= 3.1'
  gem 'webdrivers', '~> 4.2'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'annotate', '~> 3.1.1'
  gem 'better_errors'
  gem 'binding_of_caller'
  # Used to try and track down N+1 query problems
  gem 'bullet', '~> 6.1.0'
  gem 'byebug', platform: :mri
  gem 'colorize'
  gem 'guard-jasmine'
  gem 'launchy'
  gem 'parallel_tests', '~> 2.32'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rspec-collection_matchers'
  gem 'rspec-rails', '~> 3.9'
  gem 'rubocop', '~> 0.81.0', require: false
  gem 'rubocop-rspec', '~> 1.38.1', require: false
  gem 'rubocop-performance', require: false
  # TODO CT-2608: gem 'rubocop-rails', require: false
  gem 'ruby-progressbar'
  gem 'selenium-webdriver', '~> 3.142.6'
  gem 'spring-commands-rspec'
end

group :development do
  gem 'browser_sync_rails'
  gem 'guard-brakeman'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'listen', '~> 3.2.1'
  # Rather than use defualt ./git/hooks folder we use overcommit for easier
  # management
  gem 'overcommit', '~> 0.52.1'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.1'
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'yard'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
