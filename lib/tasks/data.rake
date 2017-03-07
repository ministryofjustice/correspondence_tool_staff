#################################################################
#                                                               #
#   ENSURE ALL DATA MIGRATIONS ARE IDEMPOTENT                   #
#                                                               #
#################################################################

namespace :data do
  namespace :migrate do

    desc 'run all data migrations'
    task :all => [:environment, :add_refusal_reasons] {}

    desc 'add requires refusal reasons to non-granted outcomes'
    task :add_refusal_reasons => :environmment do

    end

    desc 'Add full names and real email addresses to dev users'
    task :add_names_to_dev_users do
      puts '>>> adding full names and email addresses to dev users'
      update_development_users
    end

    desc 'Fix responded transitions where assignee and user ids are the actual object'
    task :fix_responded_transition_user_metadata => [:environment] do
      CaseTransition.responded.each do |transition|
        fix_transition_user_metadata(transition, 'user_id')
        fix_transition_user_metadata(transition, 'assignee_id')
      end
    end
  end

end

def fix_transition_user_metadata(transition, field)
  if transition.metadata[field].respond_to? :has_key?
    if transition.metadata[field].has_key? "id"
      puts "CaseTransition #{transition.id}: fixing #{field}"
      transition.update_attribute field, transition.metadata[field]["id"]
    else
      puts "CaseTransition #{transition.id}: #{field} is a hash but could not find 'id' entry"
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
