require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { :size => 1 }
end

require 'sidekiq/web'
use Rack::Session::Cookie, :secret => ENV.fetch('SESSION_SECRET_KEY')
run Sidekiq::Web
