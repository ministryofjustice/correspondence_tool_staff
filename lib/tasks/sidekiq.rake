namespace :sidekiq do

  task status: :environment do

    require 'sidekiq/api'

    queue_names = Sidekiq::Queue.all.map(&:name)

    queue_names.each do |qn|
      q = Sidekiq::Queue.new(qn)
      puts "Queue name: #{qn}"
      if q.size == 0
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

  desc 'Clear sidekiq processed and failed queues to save memory'
  task :clearQueues => :environment do

    require 'sidekiq/api'

    Sidekiq::Stats.new.reset
    Sidekiq::DeadSet.new.clear

  end
end

