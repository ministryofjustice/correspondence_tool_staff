source 'https://rubygems.org'

gem 'activerecord-session_store'
gem 'acts_as_tree', '~> 2.8'
gem 'awesome_print'
gem 'aws-sdk'
gem 'bank_holiday', git: 'https://github.com/ministryofjustice/bank_holiday.git', branch: 'bundler-fix'
gem 'business_time'
gem 'config'
gem 'devise', '~> 4.5'
gem 'draper', '3.0.1'
gem 'dropzonejs-rails', '>= 0.8'
gem 'foreman', '~> 0.85.0'
gem 'factory_bot_rails', '~> 5.0.1'
gem 'faker', '~> 1.9.3'
gem 'gov_uk_date_fields', '~> 3.1'
gem 'govuk_template',         '~> 0.23.0'
gem 'govuk_frontend_toolkit', '>= 8.0.0'
gem 'govuk_elements_rails',   '>= 3.1.2'
gem 'govuk_elements_form_builder', '>= 1.2.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'humanize_boolean'
gem 'jbuilder', '~> 2.8'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jsonb_accessor', '~> 1.0.0.beta.1'
gem 'kaminari'
gem 'libreconv', '~> 0.9.1'
gem 'logstash-event'
gem 'lograge'
gem 'mechanize', '>= 2.7.5'
gem 'mimetype-fu', '~> 0.1.2'
gem 'govuk_notify_rails'
gem 'paper_trail', '~> 10.2'
gem 'pg', '~> 1.1'
gem 'pg_search', '~> 2.1.4'
gem 'pry-rails'
gem 'puma', '~> 3.12'
gem 'pundit', '~>2.0'
gem 'rails', '~> 5.0'
gem 'rails-data-migrations', '~> 1.1.0'
gem 'recursive-open-struct'
gem 'sass-rails', '~> 5.0'
gem 'sentry-raven', '~> 2.9.0'
gem 'slim-rails', '~> 3.2'
gem 'shell-spinner'
gem 'schema_plus_enums', '~> 0.1'
gem 'sidekiq', '~> 5.2'
gem 'sidekiq-logging-json', '~> 0.0.18'
gem 'sidekiq-scheduler'

gem 'table_print'
gem 'thor-rails'
gem 'timecop'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

group :test do
  gem 'capybara'
  gem 'codeclimate-test-reporter', '~> 1.0'
  gem 'i18n-tasks', '~> 0.9.28'
  gem 'rails-controller-testing', require: false
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 4.0'
  gem 'site_prism'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'annotate'
  gem 'better_errors'
  gem 'binding_of_caller'
  # Used to try and track down N+1 query problems
  gem 'bullet'
  gem 'byebug', platform: :mri
  gem 'chromedriver-helper'
  gem 'colorize'
  gem 'guard-jasmine'
  gem 'launchy'
  gem 'parallel_tests'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rspec-collection_matchers'
  gem 'rspec-rails', '~> 3.8'
  gem 'rubocop', '~> 0.65.0', require: false
  gem 'rubocop-rspec', require: false
  gem 'ruby-progressbar'

end

group :development do
  gem 'browser_sync_rails'
  gem 'guard-brakeman'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'listen', '~> 3.1.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.1'
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'yard'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
