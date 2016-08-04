namespace :users do

  desc "Create dummy correspondence entries for demonstration purposes"
  task demo_entries: :environment do
    User::ROLES.each do |role|
      new_users = FactoryGirl.create_list(:user, 5, roles: [role])
      new_users.each do |user|
        puts "Created #{user.roles}: #{user.email}"
      end
      puts "ADDED: #{new_users.count} #{role.pluralize}"
      puts "NEW TOTAL: #{User.count} users"
    end
  end

end
