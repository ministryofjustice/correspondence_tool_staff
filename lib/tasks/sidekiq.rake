namespace :sidekiq do
  desc "sidekiq status"
  task status: :environment do
    require "sidekiq/api"

    queue_names = Sidekiq::Queue.all.map(&:name)

    queue_names.each do |qn|
      q = Sidekiq::Queue.new(qn)
      puts "Queue name: #{qn}"
      if q.empty?
        puts "   No queued jobs"
      else
        q.each do |job|
          job_detail = job.args.first
          puts "   Job id: #{job_detail['job_id']}   #{job_detail['job_class']}   args: #{job_detail['arguments'].inspect}"
        end
      end
      puts "  "
    end
  end
end
