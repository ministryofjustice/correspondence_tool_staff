require 'csv'
require File.join(Rails.root, 'lib', 'rake_task_helpers', 'host_env')

class UserSeeder

  FILENAME = ENV['USER_IMPORT_CSV']

  def initialize
    raise 'Set USER_IMPORT_CSV env var to point to the CSV file containing user data' if FILENAME.blank?
    @bg = nil
    @dir = nil
    @bu = nil
    @initial_password = (0...20).map { ('a'..'z').to_a[rand(26)] }.join
    puts "Using initial password: #{@initial_password}"
  end

  def seed!
    puts "Adding users...."
    CSV.foreach(FILENAME) do |row|
      begin
        process_row(row)
      rescue => err
        puts "Errror processing this row:"
        puts "#{err.class} - #{err.message}"
        puts '>>>>>>>>>>>>>>>>>'
        puts row
        puts '<<<<<<<<<<<<<<<<<'
        puts "Backtrace"
        puts err.backtrace
        exit
      end
    end
    populate_dev_users
    populate_hq_users
    report_userless_teams
  end


  private

  def populate_dev_users
    dacu_bmt = BusinessUnit.dacu_bmt
    dacu_dis = BusinessUnit.dacu_disclosure
    dev_user_file = File.join(File.dirname(ENV['USER_IMPORT_CSV']), 'dev_users.csv')

    CSV.foreach(dev_user_file) do |row|
      full_name, email = row
      puts "Creating dev user #{full_name}"
      user = User.create!(full_name: full_name, email: email, password: @initial_password)
      TeamsUsersRole.create!(team_id: dacu_bmt.id, user_id: user.id, role: 'manager')
      TeamsUsersRole.create!(team_id: dacu_dis.id, user_id: user.id, role: 'approver')
    end
  end


  def populate_hq_users
    hq_user_file = File.join(File.dirname(ENV['USER_IMPORT_CSV']), 'hq_users.csv')
    CSV.foreach(hq_user_file) do |row|
      team_name, full_name, role, email = row
      puts "Creating HQ user #{full_name} for team #{team_name}"
      email = normalize_email(email, full_name)
      team = BusinessUnit.find_by!(name: team_name)
      user = User.find_by(email: email)
      if user.nil?
        user = User.create!(full_name: full_name, email: email, password: @initial_password)
      end
      TeamsUsersRole.create!(team_id: team.id, user_id: user.id, role: role)
    end
  end

  def process_row(row)
    case what_type_of_row?(row)
    when :header, :blank
      nil
    when :business_group
      @bg = BusinessGroup.find_by!(name: row[0])
    when :directorate
      @dir = @bg.directorates.find_by!(name: row[1])
    when :business_unit
      @bu = @dir.business_units.find_by!(name: row[2])
      process_kilo(row)
    when :kilo
      process_kilo(row)
    end
  end

  def process_kilo(row)
    _bg, _dir, _bu, kilo_name, kilo_email = row
    kilo_email.downcase! unless kilo_email.nil?
    return if kilo_email == 'unknown' || kilo_email.blank?
    kilo_email = normalize_email(kilo_email, kilo_name)
    user = User.find_by(email: kilo_email)
    if user.nil?
      user = User.create!(full_name: kilo_name, email: kilo_email, password: '7DvUVgRx7eoxQ3NTKc897BJtExBwCTFunT')
      puts "Created user #{user.full_name} - #{user.email}"
    end

    TeamsUsersRole.create!(team_id: @bu.id, user_id: user.id, role: 'responder')
    puts "Added user #{user.full_name} to team: #{@bu.name}"
  end

  def normalize_email(email, name)
    HostEnv.prod? ? email.downcase : dummy_email(name)
  end

  def dummy_email(name)
    "correspondence-staff-dev+#{name.gsub(/\s+/, '.').downcase}@digital.justice.gov.uk"
  end


  #rubocop:disable Metrics/CyclomaticComplexity
  def what_type_of_row?(row)
    bg, dir, bu, kilo_name, kilo_email= row
    if bg.blank? && dir.blank? && bu.blank? && kilo_name.blank? && kilo_email.blank?
      :blank
    elsif row.first == 'Business Unit Group'
      :header
    elsif bg.present?
      :business_group
    elsif dir.present?
      :directorate
    elsif bu.present?
      :business_unit
    elsif kilo_name.present?
      :kilo
    else
      ap row
      raise "Unrecognised row"
    end
  end
  #rubocop:enable Metrics/CyclomaticComplexity

  def report_userless_teams
    puts ''
    puts "Analysing business units to see if there are any without users:"
    teams = []
    BusinessUnit.all.each { |bu| teams << bu.name if bu.users.none? }
    puts "There are #{teams.size} Business Units without any users:"
    teams.each do |t|
      puts "  #{t}"
    end
  end



end
