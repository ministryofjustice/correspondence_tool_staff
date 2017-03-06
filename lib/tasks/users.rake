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

    roles = {
      'assigner' => ['Ass Igner', 'correspondence-staff-dev+ass.igner@digital.justice.gov.uk'],
      'drafter' => ['Draughty Hall', 'correspondence-staff-dev+drafty.hall@digital.justice.gov.uk'],
      'approver' => ['App Rover', 'correspondence-staff-dev+app.rover@digital.justice.gov.uk'],
    }
    roles.each do |role, name_and_email|
      User.new(
        email:    name_and_email.last,
        password: '12345678',
        full_name: name_and_email.first,
        roles:    [role]
      ).save!
      puts "CREATED: #{name_and_email.first} (#{name_and_email.last})"
    end
  end
end
