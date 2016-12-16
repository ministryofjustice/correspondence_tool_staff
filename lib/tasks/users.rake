namespace :users do
  desc "Create dummy users for demonstration purposes"
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

  desc 'Create users for development.'
  task dev_entries: :environment do
    if Rails.env == 'production' && ENV['ENV'] == 'prod'
      raise 'Dev users not meant for production environments.'
    end

    User::ROLES.each do |role|
      User.new(
        email:    "#{role}@localhost",
        password: '12345678',
        roles:    [role]
      ).save!
      puts "CREATED: #{role}@localhost"
    end
  end
end
