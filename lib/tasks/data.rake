#################################################################
#                                                               #
#   ENSURE ALL DATA MIGRATIONS ARE IDEMPOTENT                   #
#                                                               #
#################################################################

namespace :data do
  namespace :migrate do

    desc 'run all data migrations'
    task :all => [:environment, :add_names_to_dev_users] {}

    desc 'Add full names and real email addresses to dev users'
    task :add_names_to_dev_users do
      puts '>>> adding full names and email addresses to dev users'
      update_development_users
    end

  end
end


def update_development_users
  user_details = {
    'assigner' => ['Ass Igner', 'correspondence-staff-dev+ass.igner@digital.justice.gov.uk'],
    'drafter' => ['Draughty Hall', 'correspondence-staff-dev+drafty.hall@digital.justice.gov.uk'],
    'approver' => ['App Rover', 'correspondence-staff-dev+app.rover@digital.justice.gov.uk'],
  }
  %w(drafter approver assigner).each do |role|
    email = "#{role}@localhost"
    user = User.where(email: email).first
    if user.nil?
      puts "Unable to find user with email #{email}"
    else
      user.email = user_details[role].last
      user.full_name = user_details[role].first
      user.save!
      puts "User #{user.full_name} updated with email #{user.email}"
    end
  end
end
