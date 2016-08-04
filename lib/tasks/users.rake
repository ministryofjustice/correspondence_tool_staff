namespace :users do

  desc "Create dummy correspondence entries for demonstration purposes"
  task demo_entries: :environment do
    new_users = FactoryGirl.create_list(:user, 10)
    new_users.each do |user|
      puts "Created: #{user.email}"
    end
    puts "ADDED: #{new_users.count} users"
    puts "NEW TOTAL: #{User.count} users"
  end

end
