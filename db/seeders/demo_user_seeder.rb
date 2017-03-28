class DemoUserSeeder

  def initialize
    @teams =  [
      ['DACU', 'dacu'],
      ['Legal Aid Authority', 'laa'],
      ['HR', 'hr'],
      ['HMCTS North East Response Unit(RSU)', 'hmctsne']
    ]

    @users = [
      ['Larry Adler', 'Legal Aid Authority'],
      ['Louis Armstrong', 'Legal Aid Authority'],
      ['Lilly Allen', 'Legal Aid Authority'],
      ['Helen Mirren', 'HMCTS North East Response Unit(RSU)'],
      ['Harvey Milk', 'HMCTS North East Response Unit(RSU)'],
      ['Hayley Mills', 'HMCTS North East Response Unit(RSU)'],
      ['Harry Redknapp', 'HR'],
      ['Helen Reddy', 'HR'],
      ['Harold Robbins', 'HR'],
      ['David Attenborough', 'DACU'],
      ['Desi Arnaz', 'DACU'],
      ['Dave Allen', 'DACU']
    ]
  end

  def seed!
    seed_teams
    seed_users
  end

  private

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
    @users.each do |user_name_and_team|
      user_name = user_name_and_team.first
      team_name = user_name_and_team.last
      email = email_from_name(user_name)
      role = team_name == 'DACU' ? 'manager' : 'responder'

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

  def email_from_name(name)
    email_name = name.downcase.tr(' ', '.').gsub(/\.{2,}/, '.')
    "correspondence-staff-dev+#{email_name}@digital.justice.gov.uk"
  end
end
