# Keep this tiny. It runs only when a Rails server boots, not during assets:precompile.
require Rails.root.join("config/business_time")

Rails.application.config.after_initialize do
  puts "Initializing business time configuration"
  BusinessTimeConfig.configure!
end
