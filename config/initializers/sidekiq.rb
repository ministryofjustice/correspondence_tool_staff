if Rails.env.production?
  Sidekiq.logger.formatter = Sidekiq::Logger::Formatters::JSON.new
end

Sidekiq.configure_client do |config|
  config.redis = {
    size: 1,
  }
end

if Rails.env.development?
  Sidekiq.configure_server do |config|
    config.redis = { url: ENV.fetch("REDIS_URL_SIDEKIQ", "redis://localhost:6379/1") }
  end

  Sidekiq.configure_client do |config|
    config.redis = {
      size: 1,
      url: ENV.fetch("REDIS_URL_SIDEKIQ", "redis://localhost:6379/1"),
    }
  end
end

require "sidekiq/web"

# Requirement since Sidekiq 5+
# Sidekiq::Extensions.enable_delay!
