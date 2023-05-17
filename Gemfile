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
gem 'aasm', '~> 5.2'
# AXLSX styler - easy styling of cells based on cell references
gem 'axlsx_styler'
gem 'awesome_print'
gem 'aws-sdk-s3'
gem 'bank_holiday', git: 'https://github.com/ministryofjustice/bank_holiday.git', branch: 'bundler-fix'
gem 'business_time'
gem 'config', '~> 4.0'
gem 'devise', '~> 4.8.1'
gem 'draper', '4.0.2'
gem 'dropzonejs-rails'
gem 'foreman', '~> 0.87.1'
gem 'factory_bot_rails', '~> 6.2.0'
gem 'faker', '~> 2.20'
gem 'gov_uk_date_fields', '~> 3.1'
gem 'govuk_template',         '~> 0.26.0'
gem 'govuk_frontend_toolkit', '>= 9.0.0'
gem 'govuk_elements_rails',   '>= 3.1.2'
gem 'govuk_elements_form_builder', '~> 1.3.0'
gem 'govuk_notify_rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'humanize_boolean'
gem 'jbuilder', '~> 2.11'
gem 'jquery-rails', '~> 4.5'
gem 'jquery-ui-rails'
gem 'jsonb_accessor', '~> 1.3.2'
gem 'kaminari'
gem 'libreconv', '~> 0.9.5'
gem 'logstash-event'
gem 'lograge'
gem 'loofah', '>= 2.3.1'
gem 'mechanize', '>= 2.7.7'
gem 'notifications-ruby-client', '>= 5.4'
gem 'omniauth-azure-activedirectory-v2', '~> 1.0.0'
gem 'omniauth-rails_csrf_protection'
gem 'paper_trail', '~> 12.3'
gem 'pg', '~> 1.3'
gem 'pg_search', '~> 2.3.6'
gem 'pry-rails'
gem 'puma', '~> 5.6'
gem 'pundit', '~>2.1'
gem 'rails', '~> 6.1.6'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false
gem 'sprockets', '~> 4.0.2'
gem 'rails-data-migrations', '~> 1.2.0'
gem 'recursive-open-struct'
gem 'sablon'
gem 'sass-rails', '~> 6.0'
gem 'sentry-ruby'
gem 'sentry-rails'
gem 'slim-rails', '~> 3.6'
gem 'shell-spinner'
gem 'sidekiq', '~> 6.4.0'

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
# Alpine does not include zoneinfo files (probably) - it asked for tinfo-data, so bundle the tzinfo-data gem
gem 'tzinfo-data'
gem 'ruby-progressbar'

group :test do
  gem 'capybara', '~> 3.37'
  gem 'i18n-tasks', '~> 1.0.12'
  gem 'rails-controller-testing', require: false
  gem 'shoulda-matchers', '~> 5.1'
  gem 'site_prism', '4.0.1'
  gem 'webdrivers', '~> 5.2.0'
  gem 'simplecov', '~> 0.22.0'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'annotate', '~> 3.2.0'
  gem 'better_errors'
  gem 'binding_of_caller'
  # Used to try and track down N+1 query problems
  gem 'bullet', '~> 7.0.1'
  gem 'byebug', platform: :mri
  gem 'colorize'
  gem 'guard-jasmine'
  gem 'launchy'
  gem 'parallel_tests', '~> 3.7'
  gem 'pry'
  gem 'pry-byebug', "3.9.0"
  gem 'rspec-collection_matchers'
  gem 'rspec-rails', '~> 5.0'
  gem 'rubocop', '~> 1.29', require: false
  gem 'rubocop-rspec', '~> 2.10', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'selenium-webdriver', '~> 4.1.0'
  gem 'spring-commands-rspec'
end

group :development do
  gem 'browser_sync_rails'
  gem 'guard-brakeman'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'listen', '~> 3.7.1'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen'
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'yard'
end
