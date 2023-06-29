require "csv"
require Rails.root.join("lib/rake_task_helpers/host_env")

class GroupEmailSeeder
  PATH = ENV["TEAM_IMPORT_CSV"]

  def initialize
    raise "Set TEAM_IMPORT_CSV env var to point to the CSV file containing team data" if PATH.blank?

    @filename = File.expand_path(File.join(PATH, "..", "group_emails.csv"))
    @bg = nil
    @dir = nil
    @bu = nil
  end

  def seed!
    CSV.foreach(@filename) do |row|
      process_row(row)
    end
  end

private

  def process_row(row)
    Rails.logger.debug "Processing row #{row.inspect}"
    return if header_row?(row)

    bg, dir, bu, _lead, _areas, email = row
    if bg.present?
      @bg = BusinessGroup.find_by(name: bg)
      Rails.logger.debug "Found Business Group #{@bg.name}"
      return
    end

    if dir.present?
      @dir = @bg.directorates.find_by!(name: dir)
      Rails.logger.debug "Found Directorate #{@dir.name}"
      return
    end

    if bu.present?
      @bu = @dir.business_units.find_by!(name: bu)
      Rails.logger.debug "Found Business Unit #{@bu.name}"
    end

    if email.present?
      email = normalize_email(email)
      @bu.update!(email:)
      Rails.logger.debug "Added email #{email} to business unit #{@bu.name}"
    end
  end

  def header_row?(row)
    row.first == "Business Unit Group"
  end

  def normalize_email(email)
    HostEnv.production? ? email.downcase : dummy_email(email)
  end

  def dummy_email(email)
    "correspondence-staff-dev+#{email.gsub(/\s+/, '.').tr('@', '-').downcase}@digital.justice.gov.uk"
  end
end
