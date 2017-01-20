namespace :cases do

  desc "Create dummy case entries for demonstration purposes"
  task demo_entries: :environment do
    FactoryGirl.create_list(:case, 10)
    puts 'Created 10 new cases'
    puts "Total cases is now: #{Case.count}"
  end

end
