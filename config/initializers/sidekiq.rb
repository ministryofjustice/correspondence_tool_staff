if Rails.env == 'production'
  Sidekiq.logger.formatter = Sidekiq::Logger::Formatters::JSON.new
end

Sidekiq.configure_client do |config|
  config.redis = {
    size: 1,
  }
end


# the following prevents sidekiq web dashboard from killing the cookie
# and forcing a new sign in for every page
#
require "sidekiq/web"

# Requirement since Sidekiq 5+
Sidekiq::Extensions.enable_delay!
