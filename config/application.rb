require_relative "boot"

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
require "active_storage/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CorrespondencePlatform
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

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

    # Use AES-256-GCM authenticated encryption for encrypted cookies.
    # Also, embed cookie expiry in signed or encrypted cookies for increased security.
    #
    # This option is not backwards compatible with earlier Rails versions.
    # It's best enabled when your entire app is migrated and stable on 5.2.
    #
    # Existing cookies will be converted on read then written with the new scheme.
    config.action_dispatch.use_authenticated_cookie_encryption = true

    # Use AES-256-GCM authenticated encryption as default cipher for encrypting messages
    # instead of AES-256-CBC, when use_authenticated_message_encryption is set to true.
    config.active_support.use_authenticated_message_encryption = true

    # Add default protection from forgery to ActionController::Base instead of in
    # ApplicationController.
    config.action_controller.default_protect_from_forgery = true

    # Use SHA-1 instead of MD5 to generate non-sensitive digests, such as the ETag header.
    config.active_support.hash_digest_class = ::Digest::SHA1

    # Make `form_with` generate id attributes for any generated HTML tags.
    config.action_view.form_with_generates_ids = true

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
