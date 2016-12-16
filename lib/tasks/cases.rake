namespace :cases do

  desc "Create dummy case entries for demonstration purposes"
  task demo_entries: :environment do
    FactoryGirl.create_list(:cases, 10)
  end

end
