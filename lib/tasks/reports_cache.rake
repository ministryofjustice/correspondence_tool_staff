namespace :reports do
  desc "Refresh cached JSON for standard reports"
  task refresh_cache: :environment do
    Rails.logger = Logger.new($stdout)
    Rails.logger.level = Logger::INFO

    result = Reports::CacheRefresher.call(logger: Rails.logger)
    puts "reports:refresh_cache => #{result.inspect}"
  end
end
