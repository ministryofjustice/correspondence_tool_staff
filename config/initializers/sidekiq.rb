require 'sidekiq/logging/json'

if Rails.env == 'production'
  Sidekiq.logger.formatter = Sidekiq::Logging::Json::Logger.new
end

Sidekiq.configure_client do |config|
  config.redis = { :size => 1 }
end
