require "csv"

class UserSeeder
  FILENAME = ENV["USER_IMPORT_CSV"]

  def initialize
    raise "Set USER_IMPORT_CSV env var to point to the CSV file containing user data" if FILENAME.blank?

    @bg = nil
    @dir = nil
    @bu = nil
    @initial_password = (0...20).map { ("a".."z").to_a[rand(26)] }.join
    Rails.logger.debug "Using initial password: #{@initial_password}"
  end

  def seed!
    Rails.logger.debug "Adding users...."
    CSV.foreach(FILENAME) do |row|
      process_row(row)
    rescue StandardError => e
      Rails.logger.debug "Error processing this row:"
      Rails.logger.debug "#{e.class} - #{e.message}"
      Rails.logger.debug ">>>>>>>>>>>>>>>>>"
      Rails.logger.debug row
      Rails.logger.debug "<<<<<<<<<<<<<<<<<"
      Rails.logger.debug "Backtrace"
      Rails.logger.debug e.backtrace
      # rubocop:disable Rails/Exit
      exit
      # rubocop:enable Rails/Exit
    end
    populate_dev_users
    populate_hq_users
    report_userless_teams
  end

private

  def populate_dev_users
    dacu_bmt = BusinessUnit.dacu_bmt
    dacu_dis = BusinessUnit.dacu_disclosure
    dev_user_file = File.join(File.dirname(ENV["USER_IMPORT_CSV"]), "dev_users.csv")

    CSV.foreach(dev_user_file) do |row|
      full_name, email = row
      Rails.logger.debug "Creating dev user #{full_name}"
      user = User.create!(full_name:, email:, password: @initial_password)
      TeamsUsersRole.create!(team_id: dacu_bmt.id, user_id: user.id, role: "manager")
      TeamsUsersRole.create!(team_id: dacu_dis.id, user_id: user.id, role: "approver")
    end
  end

  def populate_hq_users
    hq_user_file = File.join(File.dirname(ENV["USER_IMPORT_CSV"]), "hq_users.csv")
    CSV.foreach(hq_user_file) do |row|
      team_name, full_name, role, email = row
      Rails.logger.debug "Creating HQ user #{full_name} for team #{team_name}"
      email = normalize_email(email, full_name)
      team = BusinessUnit.find_by!(name: team_name)
      user = User.find_by(email:)
      if user.nil?
        user = User.create!(full_name:, email:, password: @initial_password)
      end
      TeamsUsersRole.create!(team_id: team.id, user_id: user.id, role:)
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
    return if kilo_email == "unknown" || kilo_email.blank?

    kilo_email = normalize_email(kilo_email, kilo_name)
    user = User.find_by(email: kilo_email)
    if user.nil?
      user = User.create!(full_name: kilo_name, email: kilo_email, password: SecureRandom.random_number(36**13).to_s(36))
      Rails.logger.debug "Created user #{user.full_name} - #{user.email}"
    end

    TeamsUsersRole.create!(team_id: @bu.id, user_id: user.id, role: "responder")
    Rails.logger.debug "Added user #{user.full_name} to team: #{@bu.name}"
  end

  def normalize_email(email, name)
    HostEnv.production? ? email.downcase : dummy_email(name)
  end

  def dummy_email(name)
    "correspondence-staff-dev+#{name.gsub(/\s+/, '.').downcase}@digital.justice.gov.uk"
  end

  def what_type_of_row?(row)
    bg, dir, bu, kilo_name, kilo_email = row
    if bg.blank? && dir.blank? && bu.blank? && kilo_name.blank? && kilo_email.blank?
      :blank
    elsif row.first == "Business Unit Group"
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
      Rails.logger.debug row
      raise "Unrecognised row"
    end
  end

  def report_userless_teams
    Rails.logger.debug ""
    Rails.logger.debug "Analysing business units to see if there are any without users:"
    teams = []
    BusinessUnit.all.find_each { |bu| teams << bu.name if bu.users.none? }
    Rails.logger.debug "There are #{teams.size} Business Units without any users:"
    teams.each do |t|
      Rails.logger.debug "  #{t}"
    end
  end
end
