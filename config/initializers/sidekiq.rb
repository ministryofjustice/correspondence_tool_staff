if Rails.env == 'production'
  Sidekiq.logger.formatter = Sidekiq::Logger::Formatters::JSON.new
end

Sidekiq.configure_client do |config|
  config.redis = {
    size: 1,
  }
end


require "sidekiq/web"

# Requirement since Sidekiq 5+
# Sidekiq::Extensions.enable_delay!
