desc 'run Smoke tests'

task smoke: :environment do
  require File.join(Rails.root, 'lib', 'smoketest')
  require File.join(Rails.root, 'lib', 'rake_task_helpers', 'host_env')
  
  HostEnv.safe do
    require File.join(Rails.root, 'spec', 'support', 'find_or_create_strategy')
    create_smoketest_user_if_needed
    create_test_case_if_needed
  end

  smokey = Smoketest.new
  smokey.run
end


def create_smoketest_user_if_needed
  HostEnv.safe do
    FactoryGirl.find_or_create :team_dacu
    FactoryGirl.find_or_create :team_dacu_disclosure

    new__or_existing_user = User.find_or_create_by( email: Settings.smoke_tests.username) do | user |
      user.full_name             = 'Smokey Test(DO NOT EDIT)'
      user.password              = Settings.smoke_tests.password
      user.password_confirmation = Settings.smoke_tests.password
      puts 'Created Smoke Test user'

    end

    TeamsUsersRole.find_or_create_by!(team: BusinessUnit.dacu_bmt, user: new__or_existing_user, role: 'manager') do
      puts 'Created Team/Role link to user'
    end
  end
end


def create_test_case_if_needed
  HostEnv.safe do
    if Case.none?
      FactoryGirl.create :case
      puts 'Created an unassigned case to view in the smoke tests'
    end
  end
end
