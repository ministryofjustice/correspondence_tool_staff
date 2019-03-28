require_relative 'boot'

require "rails"
# Pick the frameworks you want:		 +
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CorrespondencePlatform
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.ga_tracking_id = (ENV['GA_TRACKING_ID'] || '')

    ActionView::Base.default_form_builder = GovukElementsFormBuilder::FormBuilder

    # Ensure we dump the DB structure as SQL, required to get Postgres enums to
    # work.
    config.active_record.schema_format = :sql

    config.autoload_paths += %W(#{config.root}/lib #{config.root}/app/validators)
    config.active_job.queue_adapter = :sidekiq

    Dir[config.root.join('lib', 'extensions', '**', '*.rb')].each do |file|
      require file
    end
    config.generators.javascript_engine = :js
  end
end


