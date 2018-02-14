require 'sidekiq/logging/json'

if Rails.env == 'production'
  Sidekiq.logger.formatter = Sidekiq::Logging::Json::Logger.new
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
Sidekiq::Web.set(:sessions, { domain: ".example.com" })
