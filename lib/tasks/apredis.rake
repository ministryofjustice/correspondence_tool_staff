desc 'prints the contents of the Active Job entries is redis'
task :apredis do
  require "redis"
  require 'json'

  redis = Redis.new
  entries =  redis.lrange('queue:correspondence_tool_staff_development_mailers', 0, 999)
  entries.each do |entry|
    ap JSON.parse(entry)
    puts '*' * 50
  end

end