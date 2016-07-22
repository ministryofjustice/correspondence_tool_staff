namespace :correspondence do

  desc "Create dummy correspondence entries for demonstration purposes"
  task :demo_entries => :environment do
    FactoryGirl.create_list(:correspondence, 10)
  end

end