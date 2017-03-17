namespace :users do
  desc "Create dummy users for demonstration purposes"
  task demo_entries: :environment do
    User::ROLES.each do |role|
      new_users = FactoryGirl.create_list(:user, 5, :dev, roles: [role])
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

    managing_team =
      Team.find_or_create_by name: 'Managing Team',
                             email: 'managers@localhost'
    responding_team =
      Team.find_or_create_by name: 'Responding Team',
                             email: 'responders@localhost'
    [
      {
        full_name: 'Ass Igner',
        email: 'correspondence-staff-dev+ass.igner@digital.justice.gov.uk',
        managing_teams: [managing_team],
      },
      {
        full_name: 'Draughty Hall',
        email: 'correspondence-staff-dev+drafty.hall@digital.justice.gov.uk',
        responding_teams: [responding_team],
      }
    ].each do |user_info|
      if User.exists?(email: user_info[:email])
        puts "EXISTS: #{user_info[:full_name]} #{user_info[:email]}"
      else
        user = User.create!(user_info.merge(password: '12345678'))
        puts "CREATED: #{user_info[:full_name]} #{user_info[:email]}"
      end
    end
  end
end
