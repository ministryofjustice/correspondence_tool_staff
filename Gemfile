source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: ".ruby-version"

gem "activerecord-session_store"
gem "acts_as_tree", "~> 2.9"
# Gems to help generating with Excel spreadsheets
# undeclared (but documented) dependency on rubyzip
# This is from the readme of axlsx_rails.
gem "aasm", "~> 5.5"
gem "caxlsx"
gem "caxlsx_rails"
gem "rubyzip", ">= 1.2.4"

gem "awesome_print"
gem "aws-sdk-s3"
# AXLSX styler - easy styling of cells based on cell references
gem "axlsx_styler"
gem "bank_holiday", git: "https://github.com/ministryofjustice/bank_holiday.git", branch: "bundler-fix"
gem "business_time"
gem "config"
gem "devise"
gem "draper", "4.0.2"
gem "dropzonejs-rails"
gem "factory_bot_rails", "~> 6.4.3"
gem "faker", "~> 2.20"
gem "foreman", "~> 0.87.1"
gem "gov_uk_date_fields", "~> 3.1"
gem "govuk_elements_form_builder", "~> 1.3.0"
gem "govuk_elements_rails",   ">= 3.1.2"
gem "govuk_frontend_toolkit", ">= 9.0.0"
gem "govuk_notify_rails"
gem "govuk_template", "~> 0.26.0"
gem "httparty"
gem "humanize_boolean"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.14"
gem "jquery-rails", "~> 4.6"
gem "jquery-ui-rails"
gem "jsonb_accessor", "~> 1.4"
gem "jwe"
gem "kaminari"
gem "libreconv", "~> 0.9.5"
gem "lograge"
gem "logstash-event"
gem "loofah", ">= 2.3.1"
gem "mail", ">= 2.8"
gem "matrix" # required by prawn
gem "notifications-ruby-client", ">= 5.4"
gem "omniauth-azure-activedirectory-v2", "~> 1.0.0"
gem "omniauth-rails_csrf_protection"
gem "paper_trail"
gem "pg", "~> 1.5"
gem "pg_search", "~> 2.3.6"
gem "prawndown"
gem "puma", "~> 6.4"
gem "pundit", "~>2.4"
gem "rails", "~> 7.0"
# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.1.0", require: false
# Gem (https://github.com/anjlab/rails-data-migrations) does not support rails 7.2 so changed to this fork
# TODO: Move back to original version when it is updated
gem "rails-data-migrations", git: "https://github.com/notarize/rails-data-migrations.git", ref: "1ec8bf9"
gem "recursive-open-struct"
gem "sablon"
gem "sass-rails", "~> 6.0"
gem "sentry-rails"
gem "sentry-ruby"
gem "shell-spinner"
gem "sidekiq", "<9"
gem "slim-rails", "~> 3.7"
gem "sprockets", "~> 4.2.2"

gem "table_print"
gem "terser"
gem "timecop"
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem "turbolinks", "~> 5"
# Alpine does not include zoneinfo files (probably) - it asked for tinfo-data, so bundle the tzinfo-data gem
gem "ruby-progressbar"
gem "tzinfo-data"

group :test do
  gem "capybara", "~> 3.40"
  gem "capybara-lockstep"
  gem "i18n-tasks"
  gem "rails-controller-testing", require: false
  gem "shoulda-matchers", "~> 6.5"
  gem "simplecov"
  gem "simplecov-json", require: false
  gem "site_prism", "< 5.0"
end

group :development, :test do
  gem "annotate", "~> 3.2.0"
  gem "better_errors"
  gem "binding_of_caller"
  gem "brakeman"
  # Used to try and track down N+1 query problems
  gem "bullet"
  gem "colorize"
  gem "debug", ">= 1.0.0"
  gem "parallel_tests"
  gem "phantomjs"
  gem "rspec-collection_matchers"
  gem "rspec-rails"
  gem "rubocop-govuk", require: false
  gem "selenium-webdriver"
  gem "teaspoon-jasmine"
end
