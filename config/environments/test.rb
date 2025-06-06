require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  config.after_initialize do
    Bullet.enable = false
    # Just looking for N+1 queries at the moment - so turn off counter cache and unused eager loads
    Bullet.counter_cache_enable        = false
    Bullet.unused_eager_loading_enable = false
    Bullet.bullet_logger = true

    # These are hard to remove as they are in the admin controller who doesn't know
    # how to eager load the original case just for ICO cases
    [Case::OverturnedICO::FOI, Case::ICO::FOI, Case::ICO::SAR, Case::OverturnedICO::SAR, Case::SAR::OffenderComplaint].each do |klass|
      Bullet.add_safelist type: :n_plus_one_query,
                          class_name: klass.name,
                          association: :original_case
      Bullet.add_safelist type: :n_plus_one_query,
                          class_name: klass.name,
                          association: :original_case_link
    end
    Bullet.add_safelist type: :n_plus_one_query,
                        class_name: "LinkedCase",
                        association: :linked_case
    Bullet.add_safelist type: :n_plus_one_query,
                        class_name: "LinkedCase",
                        association: :case
    Bullet.add_safelist type: :n_plus_one_query,
                        class_name: "Assignment",
                        association: :case

    # searches are also a challenge...
    %i[retention_schedule responder message_transitions managing_assignment responder_assignment responding_team approver_assignments managing_team].each do |assoc|
      [Case::FOI::TimelinessReview,
       Case::FOI::ComplianceReview,
       Case::ICO::FOI,
       Case::FOI::Standard,
       Case::SAR::Standard,
       Case::SAR::Offender,
       Case::SAR::OffenderComplaint].each do |klass|
        Bullet.add_safelist type: :n_plus_one_query,
                            class_name: klass.name,
                            association: assoc
      end
    end

    # These 2 are a consequence of app/models/user.rb:176
    # users are related to teams (apparently), but only BusinessUnits have correspondence_types
    # so its hard to eager load without changing the code significantly
    Bullet.add_safelist type: :n_plus_one_query,
                        class_name: "BusinessUnit",
                        association: :correspondence_type_roles
    Bullet.add_safelist type: :n_plus_one_query,
                        class_name: "BusinessUnit",
                        association: :correspondence_types
    Bullet.add_safelist type: :n_plus_one_query,
                        class_name: "BusinessGroup",
                        association: :moved_to_unit
    Bullet.add_safelist type: :n_plus_one_query,
                        class_name: "Directorate",
                        association: :moved_to_unit
    Bullet.add_safelist type: :n_plus_one_query,
                        class_name: "BusinessUnit",
                        association: :moved_to_unit

    Bullet.add_safelist type: :n_plus_one_query,
                        class_name: "TeamsUsersRole",
                        association: :team
    # Enable this to track down most of the N+1 query issues
    Bullet.raise = true # raise an error if n+1 query occurs
  end
  # Settings specified here will take precedence over those in config/application.rb.

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  config.eager_load = ENV["CI"].present?

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.headers = { "Cache-Control" => "public, max-age=#{1.hour.to_i}" }

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.active_job.queue_adapter = :test

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: Settings.cts_email_url, port: Settings.cts_email_port }

  config.action_mailer.asset_host = config.action_mailer.default_url_options[:host]

  # Disable caching for Action Mailer templates even if Action Controller
  # caching is enabled.
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Unlike controllers, the mailer instance doesn't have any context about the
  # incoming request so you'll need to provide the :host parameter yourself.
  config.action_mailer.default_url_options = { host: "www.example.com" }

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  config.middleware.insert_before 0, Capybara::Lockstep::Middleware
end
