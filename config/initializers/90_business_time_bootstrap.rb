# Keep this tiny. It runs only when a Rails server boots, not during assets:precompile.
require Rails.root.join("config/business_time")
if defined?(Rails::Server)

  Rails.application.config.after_initialize do
    BusinessTimeConfig.configure!
  end
end
