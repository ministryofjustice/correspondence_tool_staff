class DevUserSeeder

  def initialize
    @teams = {
      'laa'           => BusinessUnit.find_by!(name: 'Legal Aid Agency (LAA)'),
      'hmctsne'       => BusinessUnit.find_by!(name: 'North East Regional Support Unit (NE RSU)'),
      'hr'            => BusinessUnit.find_by!(name: 'MoJ Human Resources (MoJ HR)'),
      'dacu'          => BusinessUnit.dacu_bmt,
      'dacudis'       => BusinessUnit.dacu_disclosure,
      'pressoffice'   => BusinessUnit.press_office,
      'privateoffice' => BusinessUnit.private_office,
      'commsandinfo'  => BusinessUnit.find_by!(name: 'Communications and Information'),
    }

    @users = {
      'Larry Adler'        => [{ team: 'laa',            role: 'responder' }],
      'Louis Armstrong'    => [{ team: 'laa',            role: 'responder' }],
      'Lilly Allen'        => [{ team: 'laa',            role: 'responder' }],
      'Helen Mirren'       => [{ team: 'hmctsne',        role: 'responder' }],
      'Harvey Milk'        => [{ team: 'hmctsne',        role: 'responder' }],
      'Hayley Mills'       => [{ team: 'hmctsne',        role: 'responder' }],
      'Harry Redknapp'     => [{ team: 'hr',             role: 'responder' }],
      'Helen Reddy'        => [{ team: 'hr',             role: 'responder' }],
      'Harold Robbins'     => [{ team: 'hr',             role: 'responder' }],
      'David Attenborough' => [{ team: 'dacu',           role: 'manager',
                                 admin: true }],
      'Desi Arnaz'         => [{ team: 'dacu',           role: 'manager' }],
      'Dave Allen'         => [{ team: 'dacu',          role: 'manager' },
                               { team: 'dacudis',       role: 'approver' },
                               { team: 'commsandinfo',  role: 'responder' }],
      'Dack Dispirito'     => [{ team: 'dacudis',        role: 'approver' }],
      'Dasha Diss'         => [{ team: 'dacudis',       role: 'approver' },
                               { team: 'dacu',          role: 'manager'  },
                               { team: 'commsandinfo',  role: 'responder'  }],
      'Preston Offman'     => [{ team: 'pressoffice',    role: 'approver' }],
      'Prescilla Offenberg'=> [{ team: 'pressoffice',    role: 'approver' }],
      'Primrose Offord'    => [{ team: 'privateoffice',  role: 'approver' }],
      'Princeton Office'   => [{ team: 'privateoffice',  role: 'approver' }],
    }
  end


  #rubocop:disable Metrics/MethodLength
  def seed!
    @users.each do |user_name, user_info_list|
      user_info_list.each do |user_info|
        team_abbr = user_info[:team]
        team = @teams[team_abbr]
        # team_name = @teams.find { |t| t.second == team_abbr } .first
        email = email_from_name(user_name)
        role = user_info[:role]

        user = User.where(email: email).first
        if user.nil?
          user = User.create!(full_name: user_name, email: email, password: 'correspondence')
          puts "User #{user.full_name} created with email #{user.email}"
        else
          puts "User with email #{email} already exists"
        end

        tur = TeamsUsersRole.where(team_id: team.id, user_id: user.id).first
        tur.destroy unless tur.nil?
        TeamsUsersRole.create(user: user, team: team, role: role)
        puts "Role #{role} added for User #{user.full_name} in team #{team.name}"

        if user_info.fetch(:admin, false)
          if user.admin?
            puts "Admin role for user #{user_name} already exists."
          else
            puts "Making #{user_name} an admin."
            user.team_roles.create(role: 'admin')
          end
        end
      end
    end

    # # add Dave Allen into Disclosure and Comms & Information teams as well
    # my_user = User.find_by_full_name! 'Dave Allen'
    # team = BusinessUnit.find_by_name! 'Disclosure'
    # TeamsUsersRole.find_or_create_by!(user: my_user, team: team, role: 'approver')
    # team = BusinessUnit.find_by_name 'Communications and Information'
    # TeamsUsersRole.find_or_create_by!(user: my_user, team: team, role: 'responder')

    # # add Dasha Diss into BMT and Comms and information teams as well
    # my_user = User.find_by_full_name! 'Dasha Diss'
    # team = BusinessUnit.find_by_name! 'Disclosure BMT'
    # TeamsUsersRole.find_or_create_by!(user: my_user, team: team, role: 'manager')
    # team = BusinessUnit.find_by_name 'Communications and Information'
    # TeamsUsersRole.find_or_create_by!(user: my_user, team: team, role: 'responder')


    smoketest_user = User.find_or_create_by( email: Settings.smoke_tests.username) do | user |
      user.full_name             = 'Smokey Test(DO NOT EDIT)'
      user.password              = Settings.smoke_tests.password
      user.password_confirmation = Settings.smoke_tests.password
      puts 'Created Smoke Test user'
    end

    TeamsUsersRole.find_or_create_by!(team: BusinessUnit.dacu_bmt, user: smoketest_user, role: 'manager') do
      puts 'Created Team/Role link to user'
    end
  end
  #rubocop:enable Metrics/MethodLength

  private

  def email_from_name(name)
    email_name = name.downcase.tr(' ', '.').gsub(/\.{2,}/, '.')
    "correspondence-staff-dev+#{email_name}@digital.justice.gov.uk"
  end
end
