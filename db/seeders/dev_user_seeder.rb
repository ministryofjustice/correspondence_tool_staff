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
    }

    @users = {
      'Larry Adler'        => { team: 'laa',            role: 'responder' },
      'Louis Armstrong'    => { team: 'laa',            role: 'responder' },
      'Lilly Allen'        => { team: 'laa',            role: 'responder' },
      'Helen Mirren'       => { team: 'hmctsne',        role: 'responder' },
      'Harvey Milk'        => { team: 'hmctsne',        role: 'responder' },
      'Hayley Mills'       => { team: 'hmctsne',        role: 'responder' },
      'Harry Redknapp'     => { team: 'hr',             role: 'responder' },
      'Helen Reddy'        => { team: 'hr',             role: 'responder' },
      'Harold Robbins'     => { team: 'hr',             role: 'responder' },
      'David Attenborough' => { team: 'dacu',           role: 'manager' },
      'Desi Arnaz'         => { team: 'dacu',           role: 'manager' },
      'Dave Allen'         => { team: 'dacu',           role: 'manager' },
      'Dack Dispirito'     => { team: 'dacudis',        role: 'approver' },
      'Dasha Diss'         => { team: 'dacudis',        role: 'approver' },
      'Preston Offman'     => { team: 'pressoffice',    role: 'approver' },
      'Prescilla Offenberg'=> { team: 'pressoffice',    role: 'approver' },
      'Primrose Offord'    => { team: 'privateoffice',  role: 'approver' },
      'Princeton Office'   => { team: 'privateoffice',  role: 'approver' },
    }
  end



  def seed!
    @users.each do |user_name, user_info|
      team_abbr = user_info[:team]
      team = @teams[team_abbr]
      # team_name = @teams.find { |t| t.second == team_abbr } .first
      email = email_from_name(user_name)
      role = user_info[:role]

      user = User.where(email: email).first
      if user.nil?
        user = User.create!(full_name: user_name, email: email, password: '12345678')
        puts "User #{user.full_name} created with email #{user.email}"
      else
        puts "User with email #{email} already exists"
      end

      tur = TeamsUsersRole.where(team_id: team.id, user_id: user.id).first
      tur.destroy unless tur.nil?
      TeamsUsersRole.create(user: user, team: team, role: role)
      puts "Role #{role} added for User #{user.full_name} in team #{team.name}"
    end
  end

  private

  def email_from_name(name)
    email_name = name.downcase.tr(' ', '.').gsub(/\.{2,}/, '.')
    "correspondence-staff-dev+#{email_name}@digital.justice.gov.uk"
  end
end
