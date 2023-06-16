namespace :cases do
  desc "Create dummy case entries for demonstration purposes"
  task demo_entries: :environment do
    require File.join(Rails.root, "lib", "rake_task_helpers", "host_env")

    HostEnv.safe do
      FactoryBot.create_list(:case, 10)
      puts "Created 10 new cases"
      puts "Total cases is now: #{Case::Base.count}"
    end
  end

  desc "Create mass demo"
  task massdemo: :environment do
    require File.join(Rails.root, "lib", "cts", "demo_setup")
    CTS::DemoSetup.new(1).run
  end
end
