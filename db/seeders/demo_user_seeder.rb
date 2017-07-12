class DemoUserSeeder

  def initialize
    @teams =  [
      ['DACU', 'dacu'],
      ['DACU Disclosure', 'dacudis'],
      ['Press Office', 'pressoffice'],
      ['Private Office', 'privateoffice'],
      ['Legal Aid Agency', 'laa'],
      ['HR', 'hr'],
      ['HMCTS North East Regional Support Unit (RSU)', 'hmctsne']
    ]

    @users = {
      'Larry Adler'        => { team: 'laa',         role: 'responder' },
      'Louis Armstrong'    => { team: 'laa',         role: 'responder' },
      'Lilly Allen'        => { team: 'laa',         role: 'responder' },
      'Helen Mirren'       => { team: 'hmctsne',     role: 'responder' },
      'Harvey Milk'        => { team: 'hmctsne',     role: 'responder' },
      'Hayley Mills'       => { team: 'hmctsne',     role: 'responder' },
      'Harry Redknapp'     => { team: 'hr',          role: 'responder' },
      'Helen Reddy'        => { team: 'hr',          role: 'responder' },
      'Harold Robbins'     => { team: 'hr',          role: 'responder' },
      'David Attenborough' => { team: 'dacu',        role: 'manager' },
      'Desi Arnaz'         => { team: 'dacu',        role: 'manager' },
      'Dave Allen'         => { team: 'dacu',        role: 'manager' },
      'Dack Dispirito'     => { team: 'dacudis',     role: 'approver' },
      'Dasha Diss'         => { team: 'dacudis',     role: 'approver' },
      'Preston Offman'     => { team: 'pressoffice', role: 'approver' },
      'Prescilla Offenberg'=> { team: 'pressoffice', role: 'approver' },
      'Primrose Offord'    => { team: 'privateoffice', role: 'approver' },
      'Princeton Office'   => { team: 'privateoffice', role: 'approver' },
    }
  end

  def seed!
    seed_teams
    seed_users
  end

  def seed_teams
    @teams.each do |team|
      name = team.first
      abbreviation = team.last
      team = Team.where(name: name).first
      if team.nil?
        email = "correspondence-staff-dev+#{abbreviation}-team@digital.justice.gov.uk"
        Team.create!(name: name, email: email)
        puts "Team #{name} created with group email #{email}"
      else
        puts "Team #{name} already exists"
      end
    end
  end

  def seed_users
    @users.each do |user_name, user_info|
      team_abbr = user_info[:team]
      team_name = @teams.find { |t| t.second == team_abbr } .first
      email = email_from_name(user_name)
      role = user_info[:role]

      user = User.where(email: email).first
      if user.nil?
        user = User.create!(full_name: user_name, email: email, password: '12345678')
        puts "User #{user.full_name} created with email #{user.email}"
      else
        puts "User with email #{email} already exists"
      end

      team = Team.where(name: team_name).first

      tur = TeamsUsersRole.where(team_id: team.id, user_id: user.id).first
      tur.destroy unless tur.nil?
      TeamsUsersRole.create(user: user, team: team, role: role)
      puts "Role #{role} added for User #{user.full_name} in team #{team_name}"
    end
  end

  private

  def email_from_name(name)
    email_name = name.downcase.tr(' ', '.').gsub(/\.{2,}/, '.')
    "correspondence-staff-dev+#{email_name}@digital.justice.gov.uk"
  end
end
