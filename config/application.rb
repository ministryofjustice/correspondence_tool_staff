require_relative "boot"

require "rails"
# Pick the frameworks you want:		 +
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
# require "active_storage/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CorrespondencePlatform
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.

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
    end
  end
end
