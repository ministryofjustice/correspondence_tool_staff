require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"

require_relative "../lib/business_time_config"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CorrespondencePlatform
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets db cts tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # By default associations can be empty
    config.active_record.belongs_to_required_by_default = false

    config.ga_tracking_id = (ENV["GA_TRACKING_ID"] || "")

    ActionView::Base.default_form_builder = GovukElementsFormBuilder::FormBuilder

    # Ensure we dump the DB structure as SQL, required to get Postgres enums to work.
    config.active_record.schema_format = :sql

    config.autoload_paths += %W[#{config.root}/lib]
    config.active_job.queue_adapter = :sidekiq

    Dir[config.root.join("lib", "extensions", "**", "*.rb")].each do |file|
      require file
    end
    config.generators.javascript_engine = :js

    # Use MailDeliveryJob
    config.action_mailer.delivery_job = "ActionMailer::MailDeliveryJob"

    # Set default queue name
    config.action_mailer.deliver_later_queue_name = "mailers"

    config.after_initialize do
      # instantiate a ConfigurableStateMachine::Machine on start up. This will
      # force the validation of all state machine configuration file.

      StateMachineConfigConcatenator.new.run
      begin
        ConfigurableStateMachine::Manager.instance
      rescue ConfigurationError => e
        Rails.logger.debug e.class
        Rails.logger.debug e.message
        exit # rubocop:disable Rails/Exit
      end

      BusinessTimeConfig.configure!
    end
    # Don't generate system test files.
    config.generators.system_tests = nil

    config.action_controller.raise_on_missing_callback_actions = false
  end
end
